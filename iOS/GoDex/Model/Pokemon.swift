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

struct Pokemon {
    
    var id: Int
    
    var name: String
    
    var imageUrl:String
    
    var coordinate: CLLocationCoordinate2D?
    
    static var Pokedex: Array<Pokemon>? = nil
    
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
                name = pkmn.name
                image = pkmn.imageUrl
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
    
    static func byId(id: Int) -> Pokemon {
        for pokemon in Pokedex! {
            if (pokemon.id == id){
                return pokemon
            }
        }
        return Pokemon(id: -1, name: "", imageUrl: "", coordinate: nil)
    }
    
}