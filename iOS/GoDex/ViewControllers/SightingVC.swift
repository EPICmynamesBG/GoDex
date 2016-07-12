//
//  FirstViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

class SightingVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIScrollViewDelegate {

    
    /* Storyboard linked items */
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var autoCompleteTableView: UITableView!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var autoCompleteTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @objc func hideKeyboard() {
        self.searchTextField.resignFirstResponder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func submitTap(sender: UIButton) {
        
    }
    
    /* ---- Manage auto complete dropdown visibility ---- */
    
    private func showDropdown() {
        print("Show dropdown")
        self.animateDropDownToHeight(200, completion: nil)
    }
    
    private func hideDropdown() {
        print("Hide dropdown")
        self.animateDropDownToHeight(0, completion: nil)
    }
    
    func animateDropDownToHeight(height: CGFloat, completion:(() -> Void)?) {
        UIView.animateWithDuration(0.25, delay: 0.0, options: .CurveEaseInOut, animations: {
            self.autoCompleteTableViewHeight.constant = height
            self.autoCompleteTableView.layoutIfNeeded()
        }) { (complete: Bool) in
            completion?()
        }

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
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("pokemonCell", forIndexPath: indexPath)
        cell.textLabel?.text = "Text"
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
    
    
}

