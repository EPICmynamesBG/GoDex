//
//  Pokemon.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit

struct Pokemon {
    
    var id: Int
    
    var name: String
    
    var imageUrl:String
    
    static var Pokedex: Array<Pokemon>? = nil
    
    static func arrayFromJsonData(json: Array<Dictionary<String, AnyObject>>) -> [Pokemon] {
        var pokeArr: [Pokemon] = [Pokemon]()
        for obj in json {
            let pokemon = Pokemon(id: obj["pid"] as! Int,
                                  name: obj["name"] as! String,
                                  imageUrl: obj["image"] as! String)
            pokeArr.append(pokemon)
        }
        return pokeArr
    }
    
    static func filter(str: String) -> [Pokemon] {
        var pokeArr: [Pokemon] = [Pokemon]()
        for pokemon in Pokedex! {
            if (pokemon.name.lowercaseString.containsString(str.lowercaseString)){
                pokeArr.append(pokemon)
            }
        }
        return pokeArr
    }
    
    static func validate(pokemonName: String?) -> Bool {
        if (Pokedex == nil ||
            pokemonName == nil) {
            return false
        }
        for pokemon in Pokedex! {
            if (pokemon.name.lowercaseString == pokemonName!.lowercaseString){
                return true
            }
        }
        //not found
        return false
    }
    
    static func byName(pokemonName: String) -> Pokemon? {
        for pokemon in Pokedex! {
            if (pokemon.name.lowercaseString == pokemonName.lowercaseString){
                return pokemon
            }
        }
        return nil
    }
    
}