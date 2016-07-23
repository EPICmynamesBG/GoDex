//
//  Pokemon.swift
//  GoDex
//
//  Created by Brandon Groff on 7/11/16.
//  Copyright © 2016 io.godex. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/**
 *  Object definition of a Pokemon
 */
struct Pokemon {
    
    /// the Pokemon's ID
    var id: Int
    /// the Pokemon's name
    var name: String
    /// the url for the Pokemon's image
    var imageUrl:String
    
    /// Optional: When mapping, the coordinate this Pokemon was sighted at
    var coordinate: CLLocationCoordinate2D?
    
    /// The static array of all pokemon
    static var Pokedex: Array<Pokemon>? = nil
    
    /**
     Convert an array root JSON object to an array of Pokemon
     
     - parameter json: The array based
     
     - returns: Array of Pokemon
     */
    static func arrayFromJsonData(json: Array<Dictionary<String, AnyObject>>) -> [Pokemon] {
        var pokeArr: [Pokemon] = [Pokemon]()
        for obj in json {
            var coordinates: CLLocationCoordinate2D? = nil
            if (obj["geo_lat"] != nil){
                let lat = obj["geo_lat"] as! Double
                let lon = obj["geo_long"] as! Double
                coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
            let id:Int = obj["pid"] as! Int
            var name: String
            var image: String
            if (obj["name"] == nil || obj["image"] == nil) {
                let pkmn = Pokemon.byId(id)
                name = pkmn!.name
                image = pkmn!.imageUrl
            } else {
                name = obj["name"] as! String
                image = obj["image"] as! String
            }
            let pokemon = Pokemon(id: id,
                                  name: name,
                                  imageUrl: image,
                                  coordinate: coordinates)
            pokeArr.append(pokemon)
        }
        return pokeArr
    }
    
    /**
     Filter the Pokedex by string matching Pokemon name
     
     - parameter str: filter by string
     
     - returns: Filtered Array of Pokemon
     */
    static func filter(str: String) -> [Pokemon] {
        var pokeArr: [Pokemon] = [Pokemon]()
        if (Pokedex == nil) {
            return pokeArr
        }
        for pokemon in Pokedex! {
            if (pokemon.name.lowercaseString.containsString(str.lowercaseString)){
                pokeArr.append(pokemon)
            }
        }
        return pokeArr
    }
    
    /**
     Validate that the given string is a Pokemon in the Pokedex
     
     - parameter pokemonName: the name to be tested
     
     - returns: true if valid Pokemon
     */
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
    
    /**
     Get a Pokemon from the Pokedex by name
     
     - parameter pokemonName: The name of the Pokemon to get
     
     - returns: a Pokemon if found
     */
    static func byName(pokemonName: String) -> Pokemon? {
        for pokemon in Pokedex! {
            if (pokemon.name.lowercaseString == pokemonName.lowercaseString){
                return pokemon
            }
        }
        return nil
    }
    
    /**
     Get a Pokemon from the Pokedex by Id
     
     - parameter id: the ID to get
     
     - returns: the Pokemon object
     */
    static func byId(id: Int) -> Pokemon? {
        for pokemon in Pokedex! {
            if (pokemon.id == id){
                return pokemon
            }
        }
        return nil
    }
    
}