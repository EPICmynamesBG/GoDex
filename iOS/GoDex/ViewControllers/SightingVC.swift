//
//  FirstViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit
import CoreLocation

class SightingVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIGestureRecognizerDelegate, LocationManagerDelegate, RequestManagerDelegate {

    
    /* Storyboard linked items */
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var autoCompleteTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pokemonImageView: UIImageView!
    @IBOutlet weak var notificationLabel: PokeLabel!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var embeddedInfoView: UIView!
    @IBOutlet weak var headerTextBox: PokeLabel!
    
    /// the API request object
    private var networkRequest: RequestManager!
    /// the user's selected Pokemon
    private var selectedPokemon: Pokemon?
    /// the default image below the seach bar, a Pokeball
    private var defaultPokemonImage: UIImage!
    /// the filtered Pokedex used for the search/filter bar
    private var filteredArray:[Pokemon] = [Pokemon]()
    /// the timer for hiding the notification toast
    private var notificationTimer: NSTimer? = nil
    /// the info screen overlay's container view
    private var infoView: InfoViewController? = nil
    
    // Inherited override - sets background and other basic setup
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
        
        self.autoCompleteTableView.backgroundColor = ColorPalette.DropdownBackground
        self.defaultPokemonImage = UIImage(named: "largepokeball")!.scaleToFit(self.pokemonImageView.frame)
        self.pokemonImageView.image = self.defaultPokemonImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Inherited function. Handles making sure Pokedex is populated,
     and settings the initial button state
     
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
        if (self.searchTextField.text != nil){
            if (Pokemon.validate(self.searchTextField.text!)){
                self.enableSubmitButton()
            } else {
                self.disableSubmitButton()
            }
        } else {
            self.disableSubmitButton()
        }
        
        if (SettingsManager.HasFirstSubmitBeenMade()){
            //hide the top text field
            self.headerTextBox.frame.size.height = 0
            self.view.setNeedsDisplay()
            self.headerTextBox.hidden = true
            self.headerTextBox.removeFromSuperview()
        } else {
            self.headerTextBox.hidden = false
        }
        
    }
    
    /**
     Inherited function.
     
     - parameter animated: inherited
     */
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.hideInfoView()
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
    
    /**
     Action event fired by the Submit Button. Fires 
     LocationManager to get location
     
     - parameter sender: event sender, submit button
     */
    @IBAction func submitTap(sender: UIButton) {
        LocationManager.sharedInstance().delegate = self
        LocationManager.sharedInstance().getCurrentLocation()
        self.showNotification("Submitting...", onComplete: nil)
    }
    
    /**
     Action event fired by the info button. Fires the 
     showInfoView function
     
     - parameter sender: event sender, info button
     */
    @IBAction func infoButtonTap(sender: UIButton) {
        self.showInfoView()
    }
    
    /**
     Show the info overlay with a fade animation
     */
    func showInfoView() {
        self.embeddedInfoView.alpha = 0.0
        self.embeddedInfoView.hidden = false
        UIView.animateWithDuration(0.7, animations: {
            self.embeddedInfoView.alpha = 1.0
            }) { (Bool) in
                //nothing for now
                if (self.infoView != nil) {
                    if (self.infoView!.feedbackTextView.text.characters.count > 0){
                        self.infoView!.enableFeedbackButton()
                    } else {
                        self.infoView!.disableFeedbackButton()
                    }
                }
        }
    }
    
    /**
     Hide the info view with a fade out animation
     */
    func hideInfoView() {
        UIView.animateWithDuration(0.7, animations: {
            self.embeddedInfoView.alpha = 0.0
        }) { (Bool) in
            self.embeddedInfoView.hidden = true
        }
    }
    
    
    /**
     Fade in show animation and fade out the submit button. Shows
     notification for 4 seconds
     
     - parameter message:  notification text
     - parameter complete: optional actions to run on fade completion
     */
    private func showNotification(message: String, onComplete complete: (() -> Void)?) {
        if (self.notificationTimer != nil) {
            self.notificationTimer?.invalidate()
            self.notificationTimer = nil
        }
        self.notificationTimer = NSTimer.scheduledTimerWithTimeInterval(4.0, target: self, selector: #selector(self.timerDismissNotification), userInfo: nil, repeats: false)
        self.notificationLabel.alpha = 0.0
        self.notificationLabel.hidden = false
        self.notificationLabel.text = message
        self.submitButton.enabled = false
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseIn, animations: { 
            self.notificationLabel.alpha = 1.0
            self.submitButton.alpha = 0.0
        }) { (completed: Bool) in
            self.submitButton.hidden = true
            complete?()
        }
    }
    
    /**
     Fade out animation dismiss the notification label, fade in show the submit Button
     
     - parameter onComplete: optional actions to run on fade completion
     */
    private func dismissNotification(onComplete: (() -> Void)?) {
        self.submitButton.alpha = 0.0
        self.submitButton.hidden = false
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseOut, animations: {
            self.notificationLabel.alpha = 0.0
            self.submitButton.alpha = 1.0
        }) { (completed: Bool) in
            self.notificationLabel.hidden = true
            self.submitButton.enabled = true
            onComplete?()
        }
    }
    
    /**
     Dismiss notification fired by the timer
     */
    @objc private func timerDismissNotification() {
        self.dismissNotification(nil)
    }
    
    /**
     Should always be called when auser indicates/selects a Pokemon to view.
     Sets the self.selectedPokemon value, loads the pokemonImageView image
     
     - parameter pokemon: a Pokemon
     */
    private func userSelectedPokemon(pokemon: Pokemon) {
        self.selectedPokemon = pokemon
        self.pokemonImageView.image = self.selectedPokemon!.image
    }
    
    /**
     Animated enable of submit button
     */
    private func enableSubmitButton() {
        UIView.animateWithDuration(0.2, animations: { 
            self.submitButton.backgroundColor = ColorPalette.SubmitBackground
            self.submitButton.alpha = 1.0
            }) { (Bool) in
            self.submitButton.enabled = true
        }
    }
    
    /**
     Animated disable of submit button
     */
    private func disableSubmitButton() {
        self.submitButton.enabled = false
        self.selectedPokemon = nil
        UIView.animateWithDuration(0.2) { 
            self.submitButton.backgroundColor = ColorPalette.LabelBorderGray
            self.submitButton.alpha = 0.35
        }
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
        let bottom = CGPoint(x: 0, y: self.searchTextField.frame.origin.y - 40.0)
        self.scrollView.setContentOffset(bottom, animated: true)
        self.selectedPokemon = nil
        self.pokemonImageView.image = self.defaultPokemonImage
        self.showDropdown()
        self.disableSubmitButton()
    }
    
    /**
     textField delegate func. Called on `Return` keyboard tap.
     Runs the same commands as a table cell tap, calling userSelectedPokemon
     if the text in the field is a validated Pokemon
     
     - parameter textField: the search field
     
     - returns: true
     */
    func textFieldShouldReturn(textField: UITextField) -> Bool {
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
        self.scrollView.setContentOffset(CGPointZero, animated: false)
        if (Pokemon.validate(textField.text)) {
            self.userSelectedPokemon(Pokemon.byName(textField.text!)!)
            self.enableSubmitButton()
        } else {
            self.disableSubmitButton()
        }
        textField.resignFirstResponder()
        
        return true
    }
    
    // textField delegate function. Ensures the textField gives up the keyboard
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
        if (self.searchTextField.text == "" &&
            self.pokemonImageView.image != nil) {
            //reset it
            self.pokemonImageView.image = self.defaultPokemonImage
        }
    }
    
    /**
     Called by textField eveytime the inner text changes.
     This causes the filter function to run
     
     - parameter sender: the search textField
     */
    @IBAction func textDidChange(sender: UITextField) {
        if (sender.text?.characters.count >= 1){
            self.filteredArray = Pokemon.filter(sender.text!)
            
        } else {
            if (Pokemon.Pokedex != nil){
                self.filteredArray = Pokemon.Pokedex!
            }
        }
        if (Pokemon.validate(sender.text)){
            self.selectedPokemon = Pokemon.byName(sender.text!)
            self.userSelectedPokemon(self.selectedPokemon!)
            self.enableSubmitButton()
        } else {
            self.selectedPokemon = nil
            self.pokemonImageView.image = self.defaultPokemonImage
            self.disableSubmitButton()
        }
        self.autoCompleteTableView.reloadData()
    }
    
    /* ---- Gesture Recognizer Delegate - user to ensure the tableview recieves it's taps */
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if (touch.view!.isDescendantOfView(self.autoCompleteTableView) ||
            touch.view!.isDescendantOfView(self.submitButton) ||
            touch.view!.isDescendantOfView(self.infoButton)) {
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
        LocationManager.sharedInstance().delegate = nil
        //continue with the request submission
        self.networkRequest.submitACatch(self.selectedPokemon!, coordinates: coordinates)
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
    
    /**
     The RequestManager delegate callback for a catch/sighting submission success
     */
    func RequestManagerCatchSubmitted() {
        self.showNotification("We caught it! Thanks for contributing!", onComplete: nil)
        self.selectedPokemon = nil
        self.searchTextField.text = ""
        self.pokemonImageView.image = self.defaultPokemonImage
        self.filteredArray = Pokemon.Pokedex!
        self.autoCompleteTableView.reloadData()
        self.disableSubmitButton()
        if (SettingsManager.HasFirstSubmitBeenMade() == false){
            SettingsManager.FirstSubmissionMade()
            UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseOut, animations: { 
                self.headerTextBox.frame.size.height = 0
                self.view.setNeedsDisplay()
                }, completion: { (Bool) in
                    self.headerTextBox.hidden = true
                    self.headerTextBox.removeFromSuperview()
            })
        }
    }
    
    /**
     Called by Reqeust Manager when the Pokedex is recieved
     
     - parameter pokemonArray: the Pokedex
     */
    func RequestManagerPokemonListRecieved(pokemonArray: Array<Pokemon>) {
        self.filteredArray = Pokemon.Pokedex!
        self.autoCompleteTableView.reloadData()
    }
    
    // Delegate funciton - not implemented in this view
    func RequestManagerLookupResults(results: Array<CLLocationCoordinate2D>?, pokeArr: [Pokemon]?) {
        //Not applicable in this view
    }
    
    /**
     Inherited override - sets the parent property on the embedded InfoView
     
     - parameter segue:  inherited
     - parameter sender: inherited
     */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "embeddedInfoView") {
            let destVC = segue.destinationViewController as! InfoViewController
            destVC.parent = self
            self.infoView = destVC
        }
    }
    
}

