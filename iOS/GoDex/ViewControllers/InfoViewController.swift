//
//  InfoViewController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/13/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

class InfoViewController: UIViewController {
    
    var parent: SightingVC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.6)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func closeSelf() {
        self.parent?.hideInfoView()
    }
    
    
}
