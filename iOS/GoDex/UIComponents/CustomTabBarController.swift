//
//  CustomTabBarController.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

class CustomTabBarController: UITabBarController, UITabBarControllerDelegate {
    
    // Customize the appearance of the tab bar
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        for item in self.tabBar.items! {
            let scaleFrame = CGRect(x: 0, y: 0, width: 24, height: 24)
            let image = UIImage(named: "tabpokeball")?.scaleToFit(scaleFrame)
            item.image = image?.clearImage(scaleFrame).imageWithRenderingMode(.AlwaysOriginal)
            item.selectedImage = image?.imageWithRenderingMode(.AlwaysOriginal)
            item.imageInsets = UIEdgeInsets(top: 5, left: -58, bottom: -5, right: 58)
            item.setTitleTextAttributes([NSFontAttributeName: UIFont.init(name: "Helvetica", size: 24.0)!], forState: .Normal)
            item.titlePositionAdjustment = UIOffsetMake(20, -10)
        }
        
        self.tabBar.tintColor = ColorPalette.TabBarTextSelectedColor
    }
    
    // Built in function, manipulated to provide the left/right slide effect on tab change
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