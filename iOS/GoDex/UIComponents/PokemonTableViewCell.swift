//
//  PokemonTableViewCell.swift
//  GoDex
//
//  Created by Brandon Groff on 7/12/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

/// A Basic TableViewCell with a pokemon property
class PokemonTableViewCell: UITableViewCell {
    
    var pokemon: Pokemon? = nil
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setup()
    }
    
    private func setup() {
        self.backgroundColor = UIColor.clearColor()
        self.textLabel?.textColor = ColorPalette.DropdownTextColor
        self.textLabel?.font = UIFont(name: "Helvetica", size: 16.0)
    }
    
}