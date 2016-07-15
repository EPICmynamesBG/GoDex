//
//  SecondViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class SearchPokemonVC: UIViewController, MKMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, LocationManagerDelegate, RequestManagerDelegate {
    
    /* Storyboard linked items */
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    @IBOutlet weak var autoCompleteTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var notificationLabel: UILabel!
    
    static let DEFAULT_ZOOM = 0.05
    static let MAX_ZOOM = 0.0005
    static let FULL_ZOOM_OUT = 16.0
    //Nintendo HQ, USA
    static let DEFAULT_COORDINATE = CLLocationCoordinate2D(latitude: 47.6513757, longitude: -122.141262)
    
    private var filteredArray:[Pokemon] = [Pokemon]()
    
    private var selectedPokemon: Pokemon?
    
    private var networkRequest: RequestManager!
    
    private var notificationTimer: NSTimer? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the background
        self.view.layer.insertSublayer(ColorPalette.CreateGradient(self.view.frame,
            fromColor: ColorPalette.BackgroundBlue,
            toColor: ColorPalette.BackgroundGreenish), atIndex: 0)
        // setup listener to hide keyboard when tapped outside textfield
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTap))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.networkRequest = RequestManager()
        self.networkRequest.delegate = self
        
        self.autoCompleteTableView.backgroundColor = ColorPalette.DropdownBackground
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if (Pokemon.Pokedex == nil){
            self.networkRequest.getPokemonList()
        } else {
            self.filteredArray = Pokemon.Pokedex!
            self.autoCompleteTableView.reloadData()
        }
        self.mapView.showsUserLocation = true
        LocationManager.sharedInstance().delegate = self
        LocationManager.sharedInstance().getCurrentLocation()
        
        if (!SettingsManager.HasFirstSubmitBeenMade()){
            self.showNotification("Help us be more accurate!\nPlease consider contributing a sighting.", onComplete: nil)
            //stay visible for as long as possible, so disabling the timer
            self.notificationTimer?.invalidate()
            self.notificationTimer = nil
        } else {
            self.dismissNotification(nil)
        }
        
        if (self.selectedPokemon != nil) {
            self.networkRequest.pokemonPinsLookup(self.selectedPokemon!)
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
//        self.mapView.showsUserLocation = true
//        LocationManager.sharedInstance().delegate = self
//        LocationManager.sharedInstance().getCurrentLocation()
        LocationManager.sharedInstance().delegate = nil
        self.dismissNotification(nil)
    }
    
    /**
     Hides the keyboard when tapped outside
     */
    @objc func backgroundTap() {
        self.searchTextField.resignFirstResponder()
    }

    /* ---- Manage auto complete dropdown visibility ---- */
    
    /**
     Animate showing the search dropdown
     */
    private func showDropdown() {
        self.animateDropDownToHeight(200, completion: nil)
    }
    
    /**
     Animate hiding the search dropdown
     */
    private func hideDropdown() {
        self.animateDropDownToHeight(0, completion: nil)
    }
    
    /**
     Animate the height change of the search dropdown
     
     - parameter height:     the height to go to
     - parameter completion: optional on complete code to run
     */
    func animateDropDownToHeight(height: CGFloat, completion:(() -> Void)?) {
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.autoCompleteTableViewHeight.constant = height
            self.autoCompleteTableView.layoutIfNeeded()
        }) { (complete: Bool) in
            completion?()
        }
        
    }
    
    /* ---- Map Handling --- */
    
    
    private func dropPinOnLocation(coordinates: CLLocationCoordinate2D) {
        let pin: PokePin = PokePin(pokemon: self.selectedPokemon!)
        pin.coordinate = coordinates
        self.mapView.removeAnnotation(pin)
        self.mapView.addAnnotation(pin)
    }
    
    private func dropPinsOnLocations(coorArr: [CLLocationCoordinate2D]) {
        //clear old set first
        self.mapView.removeAnnotations(self.mapView.annotations)
        var pinArr = [MKPointAnnotation]()
        for coor in coorArr {
            let pin: PokePin = PokePin(pokemon: self.selectedPokemon!)
            pin.coordinate = coor
            pinArr.append(pin)
        }
        self.mapView.addAnnotations(pinArr)
        
        if (LocationManager.sharedInstance().lastRecievedCoordinates != nil) {
            let zoom = self.calculateZoomRadius(LocationManager.sharedInstance().lastRecievedCoordinates!, coordinateArray: coorArr)
            self.zoomOnLocation(zoom.CenterPoint, withCoorSpan: zoom.ZoomSpan)
        } else {
            let zoom = self.calculateZoomRadius(SearchPokemonVC.DEFAULT_COORDINATE, coordinateArray: coorArr)
            self.zoomOnLocation(zoom.NearestPin, withCoorSpan: zoom.ZoomSpan)
        }
    }
    
    private func calculateZoomRadius(userCoor: CLLocationCoordinate2D, coordinateArray: [CLLocationCoordinate2D]) -> (CenterPoint: CLLocationCoordinate2D, ZoomSpan: MKCoordinateSpan, NearestPin: CLLocationCoordinate2D) {
        var nearestCoor: CLLocationCoordinate2D? = nil
        
        for coor in coordinateArray {
            let dist = userCoor.distanceTo(coor)
            if (nearestCoor == nil){
                nearestCoor = coor
            } else if (dist < userCoor.distanceTo(nearestCoor!)) {
                nearestCoor = coor
            }
        }
        
        let avgLat = (userCoor.latitude + nearestCoor!.latitude) / 2.0
        let avgLon = (userCoor.longitude + nearestCoor!.longitude) / 2.0
        let center = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLon)

        let latDelta = abs((userCoor.latitude - nearestCoor!.latitude))
        let lonDelta = abs((userCoor.longitude - nearestCoor!.longitude))
    
        let span = MKCoordinateSpan(latitudeDelta: latDelta * 1.15, longitudeDelta: lonDelta * 1.15)
        
        return (center, span, nearestCoor!)
    }
    
    func zoomOnLocation(coordinates: CLLocationCoordinate2D, withZoomRadius radius: Double) {
        let span = MKCoordinateSpan(latitudeDelta: radius, longitudeDelta: radius)
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinates, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func zoomOnLocation(coordinates: CLLocationCoordinate2D, withCoorSpan span: MKCoordinateSpan) {
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinates, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if  annotation as? PokePin == nil{
            return nil
        }
        
        let reuseId = "test"
        
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView?.canShowCallout = true
        }
        else {
            anView?.annotation = annotation
        }
        
        //Set annotation-specific properties **AFTER**
        //the view is dequeued or created...
        
        let cpa = annotation as! PokePin
        AsyncImageLoader.LoadImage(cpa.pokemon!.imageUrl, onComplete: { (image: UIImage) in
            anView?.image = image.scaleToFit(CGRect(x: 0, y: 0, width: 32, height: 32))
        }) { (error:NSError?, message:String?) in
                //stuff
        }
        
        return anView
    }
    
    /* ---- Table View Delegate ---- */
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tappedCell = tableView.cellForRowAtIndexPath(indexPath)
        if (tappedCell != nil) {
            let pokeCell = tappedCell as! PokemonTableViewCell
            self.searchTextField.text = pokeCell.textLabel?.text
            self.userSelectedPokemon(pokeCell.pokemon!)
        }
        self.searchTextField.resignFirstResponder()
        //start the search!
    }
    
    private func userSelectedPokemon(pokemon: Pokemon) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.selectedPokemon = pokemon
        self.networkRequest.pokemonPinsLookup(self.selectedPokemon!)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredArray.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell", forIndexPath: indexPath) as! PokemonTableViewCell
        
        if (Pokemon.Pokedex != nil) {
            cell.textLabel?.text = self.filteredArray[indexPath.row].name
            cell.pokemon = self.filteredArray[indexPath.row]
        }
        
        return cell
    }
    
    /* ---- Text Field Delegate ---- */
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.selectedPokemon = nil
        if (Pokemon.Pokedex != nil){
            self.filteredArray = Pokemon.Pokedex!
            self.autoCompleteTableView.reloadData()
        }
        self.showDropdown()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (Pokemon.validate(self.searchTextField.text)){
            self.userSelectedPokemon(Pokemon.byName(self.searchTextField.text!)!)
        }
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        self.hideDropdown()
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    @IBAction func textDidChange(sender: UITextField) {
        //TODO: Filter results here
        if (sender.text?.characters.count >= 1){
            self.filteredArray = Pokemon.filter(sender.text!)
        } else {
            if (Pokemon.Pokedex != nil){
                self.filteredArray = Pokemon.Pokedex!
            }
        }
        self.autoCompleteTableView.reloadData()
    }
    
    /* ---- Gesture Recognizer Delegate - user to ensure the tableview recieves it's taps */
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isDescendantOfView(self.autoCompleteTableView)) {
            return false
        }
        return true
    }
    
    /* ---- Location Manager Delegate ---- */
    
    func locationManagerCurrentLocationRecieved(location: CLLocation, coordinates: CLLocationCoordinate2D) {
        LocationManager.sharedInstance().delegate = nil
        self.zoomOnLocation(coordinates, withZoomRadius: SearchPokemonVC.DEFAULT_ZOOM)
    }
    
    func locationManagerUpdateError(error: NSError?, message: String?) {
//        if (message != nil){
//            self.showNotification("\(message!).\nAre location services enabled?", onComplete: nil)
//        } else {
//            self.showNotification("Hmm, we couldn't get your location.\nAre location services enabled?", onComplete: nil)
//        }
        self.showNotification("Hmm, we couldn't get your location.\nAre location services enabled?", onComplete: nil)
    }
    
    /* ----- Request Manager Delegate ---- */
    
    func RequestManagerError(error: NSError?, withMessage message: String?) {
        if (message != nil) {
            self.showNotification("Whoops, did the Internet break?\n\(message!)", onComplete: nil)
        } else {
            self.showNotification("Whoops, did the Internet break?\nNothing was found...", onComplete: nil)
        }
    }
    
    func RequestManagerCatchSubmitted() {
        //Not applicable in this view
    }
    
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>) {
        self.filteredArray = Pokemon.Pokedex!
        self.autoCompleteTableView.reloadData()
    }
    
    func RequestManagerLookupResults(results: Array<CLLocationCoordinate2D>?) {
        if (results == nil ||
            results?.count == 0) {
            if (self.selectedPokemon != nil) {
                self.showNotification("Whoops, there weren't any locations found for \(self.selectedPokemon!.name).", onComplete: nil)
            } else {
                self.showNotification("Whoops, there weren't any locations found for this pokemon.", onComplete: nil)
            }
        } else {
            self.dropPinsOnLocations(results!)
        }
    }
    
    /**
     Fade in show animation and fade out the submit button. Shows
     notification for 4 seconds
     
     - parameter message:  notification text
     - parameter complete: optional actions to run on fade completion
     */
    private func showNotification(message: String, onComplete complete: (() -> Void)?) {
        if (self.notificationTimer != nil){
            self.notificationTimer?.invalidate()
            self.notificationTimer = nil
        }
        
        self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(self.timerDismissNotification), userInfo: nil, repeats: false)
        self.notificationLabel.alpha = 0.0
        self.notificationLabel.hidden = false
        self.notificationLabel.text = message
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: {
            self.notificationLabel.alpha = 1.0
        }) { (completed: Bool) in
            complete?()
        }
    }
    
    /**
     Fade out animation dismiss the notification label, fade in show the submit Button
     
     - parameter onComplete: optional actions to run on fade completion
     */
    private func dismissNotification(onComplete: (() -> Void)?) {
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: {
            self.notificationLabel.alpha = 0.0
        }) { (completed: Bool) in
            self.notificationLabel.hidden = true
            onComplete?()
        }
    }
    
    /**
     Dismiss notification fired by the timer
     */
    @objc private func timerDismissNotification() {
        self.dismissNotification(nil)
    }

}

