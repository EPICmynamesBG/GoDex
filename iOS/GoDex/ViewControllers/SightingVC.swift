//
//  FirstViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit
import CoreLocation

class SightingVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, LocationManagerDelegate, RequestManagerDelegate {

    
    /* Storyboard linked items */
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var autoCompleteTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var networkRequest: RequestManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //set the background
        self.view.layer.insertSublayer(ColorPalette.CreateGradient(self.view.frame,
            fromColor: ColorPalette.BackgroundBlue,
            toColor: ColorPalette.BackgroundGreenish), atIndex: 0)
        
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
    
    
    @IBAction func submitTap(sender: UIButton) {
        LocationManager.sharedInstance().delegate = self
        LocationManager.sharedInstance().getCurrentLocation()
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
        let bottom = CGPoint(x: 0, y: self.searchTextField.frame.origin.y - 20.0)
        self.scrollView.setContentOffset(bottom, animated: true)
        self.showDropdown()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        self.hideDropdown()
        self.scrollView.setContentOffset(CGPointZero, animated: true)
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
    }
    
    @IBAction func textDidChange(sender: UITextField) {
        print("Text changed to \(sender.text)")
    }
    
    /* ---- Scroll View Delegate ---- */
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.searchTextField.resignFirstResponder()
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
        
        //continue with the request submission
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
        //TODO
    }
    
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>) {
        Pokemon.Pokedex = pokemonArray
        self.autoCompleteTableView.reloadData()
    }
    
    func RequestManagerLookupResults(results: Array<CLLocationCoordinate2D>?) {
        //Not applicable in this view
    }
    
}

