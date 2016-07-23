//
//  InfoViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/13/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

class InfoViewController: UIViewController, UITextViewDelegate, UIGestureRecognizerDelegate {
    
    /// The controller this view is embedded in
    var parent: SightingVC?
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var disclaimerButton: UIButton!
    @IBOutlet weak var feedbackTextView: UITextView!
    @IBOutlet weak var sendFeedbackButton: UIButton!
    
    /// The network call manager
    private var networker: RequestManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.networker = RequestManager()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.backgroundTap))
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        self.view.layer.insertSublayer(ColorPalette.CreateGradient(self.view.frame,
            fromColor: ColorPalette.BackgroundGradientDarkGray,
            toColor: ColorPalette.BackgroundGradientGray), atIndex: 0)
        self.disclaimerButton.titleLabel?.numberOfLines = 3
        self.disclaimerButton.titleLabel?.textAlignment = .Center
        self.view.setNeedsDisplay()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    /**
     Hides the keyboard when tapped outside
     */
    @objc func backgroundTap() {
        self.feedbackTextView.resignFirstResponder()
    }
    
    /* ---- Button tap actions ---- */
    
    @IBAction func closeTap(sender: UIButton) {
        self.parent?.hideInfoView()
    }
    
    @IBAction func sendFeedbackTap(sender: UIButton) {
        self.feedbackTextView.resignFirstResponder()
        self.submitFeedback()
    }
    
    @IBAction func disclaimerTap(sender: UIButton) {
        UIApplication.sharedApplication().openURL(NSURL(string: "http://godex.io/policy")!)
    }
    
    /* --- Text View Delegate funcs ---- */
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        let bottom = CGPoint(x: 0, y: self.feedbackTextView.frame.origin.y - 60.0)
        self.scrollView.setContentOffset(bottom, animated: true)
        return true
    }

    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        self.feedbackTextView.resignFirstResponder()
        self.scrollView.setContentOffset(CGPoint(x: 0, y: self.feedbackTextView.frame.origin.y - self.feedbackTextView.frame.size.height), animated: true)
        return true
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView.text.characters.count > 0 {
            self.enableFeedbackButton()
        } else {
            self.disableFeedbackButton()
        }
    }
    
    /* --- Custom funcs ---- */
    
    /**
     Submit feedback, display UIAlertController appropriately on success/failure
     */
    private func submitFeedback() {
        if (self.feedbackTextView.text != nil &&
            self.feedbackTextView.text?.characters.count > 0){
            self.networker.sendFeedback(self.feedbackTextView.text!, onSuccess: { (json:Array<Dictionary<String, AnyObject>>) in
                
                if (json.count > 0){
                    if (json[0]["feedback"] != nil){
                        let alert = UIAlertController(title: "We got it!", message: "The GoDex.io community thanks you for your contribution!", preferredStyle: .Alert)
                        let ok = UIAlertAction(title: "👍", style: .Default, handler: nil)
                        alert.addAction(ok)
                        NSOperationQueue.mainQueue().addOperationWithBlock({
                            self.presentViewController(alert, animated: true, completion: { Void in
                                self.feedbackTextView.text = ""
                            })
                        })
                    }
                }
                }, onError: { (error:NSError?, message:String?) in
                    let alert = UIAlertController(title: "Oh no...", message: message, preferredStyle: .Alert)
                    let ok = UIAlertAction(title: "I will! 👍", style: .Default, handler: nil)
                    alert.addAction(ok)
                    NSOperationQueue.mainQueue().addOperationWithBlock({ 
                        self.presentViewController(alert, animated: true, completion: nil)
                    })
            })
        }
    }
    
    /**
     Disables the Feedback button, Animated
     */
    func disableFeedbackButton() {
        self.sendFeedbackButton.enabled = false
        UIView.animateWithDuration(0.3) { 
            self.sendFeedbackButton.alpha = 0.3
        }
    }
    
    /**
     Enable the feedback button, Animated
     */
    func enableFeedbackButton() {
        UIView.animateWithDuration(0.3, animations: { 
            self.sendFeedbackButton.alpha = 1.0
            }) { (Bool) in
                self.sendFeedbackButton.enabled = true
        }
    }
    
    
}
