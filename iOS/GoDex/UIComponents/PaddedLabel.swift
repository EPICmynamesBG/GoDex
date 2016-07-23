//
//  PaddedLabel.swift
//  GoDex
//
//  Created by Brandon Groff on 7/13/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import UIKit

class PaddedLabel: UILabel {
    
    private struct Defaults {
        private static let Padding: CGFloat = 5
        private static let Insets = UIEdgeInsets(top: Defaults.Padding, left: Defaults.Padding, bottom: Defaults.Padding, right: Defaults.Padding)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.numberOfLines = 0
    }
    
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, Defaults.Insets))
    }
    
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var currentRect = super.textRectForBounds(UIEdgeInsetsInsetRect(bounds, Defaults.Insets), limitedToNumberOfLines: 0)
        currentRect.origin.x -= Defaults.Insets.left
        currentRect.origin.y -= Defaults.Insets.top
        currentRect.size.width += (Defaults.Padding * 2.0)
        currentRect.size.height += (Defaults.Padding * 2.0)
        return currentRect
    }
    
}
