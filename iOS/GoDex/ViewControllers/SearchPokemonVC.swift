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
    
    private var networkRequest: RequestManager!
    
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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        print("Show dropdown")
        self.animateDropDownToHeight(200, completion: nil)
    }
    
    /**
     Animate hiding the search dropdown
     */
    private func hideDropdown() {
        print("Hide dropdown")
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
    
    
    func dropPinOnLocation(coordinates: CLLocationCoordinate2D) {
        let pin = MapPin(coordinate: coordinates, title: nil, subtitle: nil)
        self.mapView.addAnnotation(pin)
    }
    
    func zoomOnLocation(coordinates: CLLocationCoordinate2D, withZoomRadius radius: Double) {
        
    }
    
    func mapViewDidFinishLoadingMap(mapView: MKMapView) {
        LocationManager.sharedInstance().delegate = self
        LocationManager.sharedInstance().getCurrentLocation()
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        }
        
        if (annotation.isKindOfClass(MapPin)) {
            let pin = annotation as! MapPin
            //Maybe?
            mapView.translatesAutoresizingMaskIntoConstraints = true
            
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("MapPin") as MKAnnotationView!
            if (annotationView == nil) {
                annotationView = pin.annotationView()
            } else {
                annotationView.annotation = annotation;
            }
            self.addBounceAnimationToView(annotationView)
            return annotationView
        }
        else {
            return nil
        }
    }
    
    private func addBounceAnimationToView(view: UIView) {
        let bounceAnimation = CAKeyframeAnimation(keyPath: "transform.scale") as CAKeyframeAnimation
        bounceAnimation.values = [ 0.05, 1.1, 0.9, 1]
        
        let timingFunctions = NSMutableArray(capacity: bounceAnimation.values!.count)
        
        for _ in 0 ..< bounceAnimation.values!.count {
        timingFunctions.addObject(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))
        }
        bounceAnimation.timingFunctions = timingFunctions as NSArray as? [CAMediaTimingFunction]
        bounceAnimation.removedOnCompletion = false
        
        view.layer.addAnimation(bounceAnimation, forKey: "bounce")
    }
    
    /* ---- Table View Delegate ---- */
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        print("Selected \(indexPath.row)")
        let tappedCell = tableView.cellForRowAtIndexPath(indexPath)
        if (tappedCell != nil) {
            print("tapped cell it not nil")
            self.searchTextField.text = tappedCell?.textLabel?.text
        }
        self.searchTextField.resignFirstResponder()
        //start the search!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Pokemon.Pokedex != nil ? Pokemon.Pokedex!.count : 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell", forIndexPath: indexPath) as! PokemonTableViewCell
        
        if (Pokemon.Pokedex != nil) {
            cell.textLabel?.text = Pokemon.Pokedex![indexPath.row].name
            cell.pokemon = Pokemon.Pokedex![indexPath.row]
        }
        
        return cell
    }
    
    /* ---- Text Field Delegate ---- */
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.showDropdown()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
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
        print("Text changed to \(sender.text)")
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
        print(coordinates)
        LocationManager.sharedInstance().delegate = nil
        self.dropPinOnLocation(coordinates)
    }
    
    func locationManagerUpdateError(error: NSError?, message: String?) {
        let alert = UIAlertController(title: "Geolocation Error", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    /* ----- Request Manager Delegate ---- */
    
    func RequestManagerError(error: NSError?, withMessage message: String?) {
        let alert = UIAlertController(title: "Network Error", message: message, preferredStyle: .Alert)
        let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(okAction)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func RequestManagerCatchSubmitted() {
        //Not applicable in this view
    }
    
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>) {
        Pokemon.Pokedex = pokemonArray
        self.autoCompleteTableView.reloadData()
    }
    
    func RequestManagerLookupResults(results: Array<CLLocationCoordinate2D>?) {
        //TODO
    }

}

