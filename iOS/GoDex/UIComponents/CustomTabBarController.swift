//
//  CustomTabBarController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        for item in self.tabBar.items! {
            item.image = nil
            item.setTitleTextAttributes([NSFontAttributeName: UIFont.boldSystemFontOfSize(20.0)], forState: .Normal)
            item.titlePositionAdjustment = UIOffsetMake(0, -10)
        }
        
//        self.tabBar.tintColor = ColorPalette.Black
//        
//        //dynamic resizing
//        var backgroundImage = UIImage(named: "tab-bar-background")
//        backgroundImage = backgroundImage?.resizeTo(CGSizeMake(self.tabBar.frame.size.width, self.tabBar.frame.size.height))
//        self.tabBar.backgroundImage = backgroundImage
//        
//        //dynamic resizing
//        var highlightImage = UIImage(named: "tab-bar-selected-background")
//        highlightImage = highlightImage?.resizeTo(CGSizeMake(self.tabBar.frame.size.width / 2, self.tabBar.frame.size.height))
//        self.tabBar.selectionIndicatorImage = highlightImage
    }
    
    
    
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        
        let tabViewControllers = tabBarController.viewControllers!
        let fromView = tabBarController.selectedViewController!.view
        let toView = viewController.view
        
        if (fromView == toView) {
            return false
        }
        
        let fromIndex = tabViewControllers.indexOf(tabBarController.selectedViewController!)
        let toIndex = tabViewControllers.indexOf(viewController)
        
        let offScreenRight = CGAffineTransformMakeTranslation(toView.frame.width, 0)
        let offScreenLeft = CGAffineTransformMakeTranslation(-toView.frame.width, 0)
        
        // start the toView to the right of the screen
        
        
        if (toIndex < fromIndex) {
            toView.transform = offScreenLeft
            fromView.transform = offScreenRight
        } else {
            toView.transform = offScreenRight
            fromView.transform = offScreenLeft
        }
        
        fromView.tag = 124
        toView.addSubview(fromView)
        
        self.view.userInteractionEnabled = false
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 1, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            toView.transform = CGAffineTransformIdentity
            
            }, completion: { finished in
                
                let subViews = toView.subviews
                for subview in subViews{
                    if (subview.tag == 124) {
                        subview.removeFromSuperview()
                    }
                }
                tabBarController.selectedIndex = toIndex!
                self.view.userInteractionEnabled = true
                
        })
        
        return true
    }
    
}