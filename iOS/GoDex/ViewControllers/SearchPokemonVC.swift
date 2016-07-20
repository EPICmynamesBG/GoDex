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
    
    /// the filtered Pokedex used for the search/filter bar
    private var filteredArray:[Pokemon] = [Pokemon]()
    
    /// the user's selected Pokemon
    private var selectedPokemon: Pokemon?
    
    /// the API request object
    private var networkRequest: RequestManager!
    /// the timer for hiding the notification toast
    private var notificationTimer: NSTimer? = nil
    
    // Inherited override - sets the background and other basic setup
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
    
    /**
     Inherited function. Handles making sure Pokedex is populated,
     showing the user on the map, and showing the `no contribution` banner
     
     - parameter animated: inherited
     */
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
    
    /**
     Inherited function.
     
     - parameter animated: <#animated description#>
     */
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        LocationManager.sharedInstance().delegate = nil
        self.dismissNotification(nil)
    }
    
    /**
     Hides the keyboard when background tapped
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
    
    /**
     Drop Pokemon pins on the map
     
     - parameter coorArr: the array of coordinates that corresponds with the Pokemon Array
     - parameter pokeArr: the array of Pokemon to show
     */
    private func dropPinsOnLocations(coorArr: [CLLocationCoordinate2D], pokeArr: [Pokemon]) {
        //clear old set first
        self.mapView.removeAnnotations(self.mapView.annotations)
        var pinArr = [MKPointAnnotation]()
        for pokemon in pokeArr {
            if (pokemon.coordinate != nil){
                let pin: PokePin = PokePin(pokemon: pokemon)
                pin.coordinate = pokemon.coordinate!
                pinArr.append(pin)
            }
        }
        self.mapView.addAnnotations(pinArr)
        
        if (LocationManager.sharedInstance().lastRecievedCoordinates != nil) {
            let zoom = self.calculateZoomRadius(LocationManager.sharedInstance().lastRecievedCoordinates!, coordinateArray: coorArr)
            self.zoomOnLocation(zoom.CenterPoint, withCoorSpan: zoom.ZoomSpan)
        } else {
            let zoom = self.calculateZoomRadius(LocationManager.DEFAULT_COORDINATE, coordinateArray: coorArr)
            self.zoomOnLocation(zoom.NearestPin, withCoorSpan: zoom.ZoomSpan)
        }
    }
    
    /**
     Calculates the zoom radius between the user and the nearest coordinate in the array
     
     - parameter userCoor:        the user's coordinate
     - parameter coordinateArray: the array of Pokemon coordinates
     
     - returns: the calculated CenterPoint, span of zoom, and the nearest found Pokemon  pin (coordinate)
     */
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
    
    /**
     Perform a map zoom on a coordinate given a coordinate span
     
     - parameter coordinates: the coordinate to center the map on
     - parameter span:        the span/region to show
     */
    func zoomOnLocation(coordinates: CLLocationCoordinate2D, withCoorSpan span: MKCoordinateSpan) {
        let region: MKCoordinateRegion = MKCoordinateRegion(center: coordinates, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    /**
     Inheritance function override. Used to give PokePins their custom Pokemon images
     
     - parameter mapView:    the view's mapView
     - parameter annotation: the annotation (aka pin)
     
     - returns: an annotationView
     */
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
    
    /**
     Used to handle cell taps. On tap, will call userSelectedPokemon with
     the cell (aka pokemon) that was tapped
     
     - parameter tableView: the affected tableView
     - parameter indexPath: the indexPath to the tapped cell
     */
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
    
    /**
     Should always be called when auser indicates/selects a Pokemon to view
     
     - parameter pokemon: a Pokemon
     */
    private func userSelectedPokemon(pokemon: Pokemon?) {
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.selectedPokemon = pokemon
        self.networkRequest.pokemonPinsLookup(self.selectedPokemon)
    }
    
    // TableView delegate function
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.filteredArray.count
    }
    
    // Table view delegate function - sets the data for each tableView cell
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell", forIndexPath: indexPath) as! PokemonTableViewCell
        
        if (Pokemon.Pokedex != nil) {
            cell.textLabel?.text = self.filteredArray[indexPath.row].name
            cell.pokemon = self.filteredArray[indexPath.row]
        }
        
        return cell
    }
    
    /* ---- Text Field Delegate ---- */
    
    /**
     Delegate function. Sets up the dropdown and shows it when 
     textField is selected
     
     - parameter textField: the search textField
     */
    func textFieldDidBeginEditing(textField: UITextField) {
        self.selectedPokemon = nil
        if (Pokemon.Pokedex != nil){
            self.filteredArray = Pokemon.Pokedex!
            self.autoCompleteTableView.reloadData()
        }
        self.showDropdown()
    }
    
    /**
     textField delegate func. Called on `Return` keyboard tap.
     Runs the same commands as a table cell tap, calling userSelectedPokemon
     if the text in the field is a validated Pokemon
     
     - parameter textField: the search field
     
     - returns: true
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (Pokemon.validate(self.searchTextField.text)){
            self.userSelectedPokemon(Pokemon.byName(self.searchTextField.text!)!)
        } else {
            self.userSelectedPokemon(nil)
        }
        textField.resignFirstResponder()
        return true
    }
    
    /**
     textField delegate function. Hides the dropdown and tells the textField
     to hide the keyboard
     
     - parameter textField: the search textField
     
     - returns: true
     */
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        self.hideDropdown()
        textField.resignFirstResponder()
        return true
    }
    
    // textField delegate function. Ensures the textField gives up the keyboard
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
    
    /**
     Delegate func. Called by LocationManager when the user's location is recieved.
     Handles calling userSelectedPokemon if self.selectedPokemon is set
     
     - parameter location:    the user's current location
     - parameter coordinates: the user's location coordinates
     */
    func locationManagerCurrentLocationRecieved(location: CLLocation, coordinates: CLLocationCoordinate2D) {
        self.mapView.showsUserLocation = true
        LocationManager.sharedInstance().delegate = nil
        if self.selectedPokemon == nil {
            self.userSelectedPokemon(nil)
        } else {
            self.userSelectedPokemon(self.selectedPokemon!)
        }
        
    }
    
    /**
     Delegate func. Called by LocationManager when an error getting the user's location occurs.
     Displays a meaningful message
     
     - parameter error:   optional error object
     - parameter message: optional human discernable message
     */
    func locationManagerUpdateError(error: NSError?, message: String?) {
        self.showNotification("Hmm, we couldn't get your location.\nAre location services enabled?", onComplete: nil)
    }
    
    /* ----- Request Manager Delegate ---- */
    
    /**
     Called by RequestManager when an error occurs. Shows a notification
     
     - parameter error:   optional error object
     - parameter message: optional human discernable message
     */
    func RequestManagerError(error: NSError?, withMessage message: String?) {
        if (message != nil) {
            self.showNotification("Whoops, did the Internet break?\n\(message!)", onComplete: nil)
        } else {
            self.showNotification("Whoops, did the Internet break?\nNothing was found...", onComplete: nil)
        }
    }
    
    // Delegate function - not implemented in this view
    func RequestManagerCatchSubmitted() {
        //Not applicable in this view
    }
    
    /**
     Called by Reqeust Manager when the Pokedex is recieved
     
     - parameter pokemonArray: the Pokedex
     */
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>) {
        self.filteredArray = Pokemon.Pokedex!
        self.autoCompleteTableView.reloadData()
    }
    
    /**
     Called by Request Manager when Pokemon location lookup data is
     recieved and processed.
     
     - parameter results: the array of Pokemon coordinates, corresponding to the Pokemon array
     - parameter pokeArr: the array of Pokemon
     */
    func RequestManagerLookupResults(results: [CLLocationCoordinate2D]?, pokeArr: Array<Pokemon>?) {
        if (results == nil ||
            pokeArr == nil) {
            if (self.selectedPokemon != nil) {
                self.showNotification("Whoops, there weren't any locations found for \(self.selectedPokemon!.name).", onComplete: nil)
            } else {
                self.showNotification("Whoops, there weren't any locations found.", onComplete: nil)
            }
        } else {
            self.dropPinsOnLocations(results!, pokeArr: pokeArr!)
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

