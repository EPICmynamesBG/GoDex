//
//  PokeLabel.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

/// A Custom Pokemon label to be used with the Pokemon font
class PokeLabel: UILabel {
    
    /**
     *  The default values for a PokeLabel
     */
    private struct Defaults {
        private static let BorderRadius: CGFloat = 6.0
        private static let BorderWidth: CGFloat = 0.9
        private static let BorderColor: UIColor = ColorPalette.LabelBorderGray
        private static let Padding: CGFloat = 20
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
    
    /**
     Configure the label's border, corner radius
     */
    private func setup() {
        self.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.57)
        self.borderWidth = Defaults.BorderWidth
        self.cornerRadius = Defaults.BorderRadius
        self.borderColor = Defaults.BorderColor
        self.numberOfLines = 0
    }
    
    // Forces label to calculate size with the insets (aka padding)
    override func drawTextInRect(rect: CGRect) {
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, Defaults.Insets))
    }
    
    // Helper in forcing label size to include insets (aka padding)
    override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var currentRect = super.textRectForBounds(UIEdgeInsetsInsetRect(bounds, Defaults.Insets), limitedToNumberOfLines: 0)
        currentRect.origin.x -= Defaults.Insets.left
        currentRect.origin.y -= Defaults.Insets.top
        currentRect.size.width += (Defaults.Padding * 2.0)
        currentRect.size.height += (Defaults.Padding * 2.0)
        return currentRect
    }
    
}
