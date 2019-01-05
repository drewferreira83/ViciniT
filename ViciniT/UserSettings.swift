//
//  UserSettings.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 9/30/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit


class UserSettings: NSObject {
    static let shared = UserSettings()

    private var defaults = UserDefaults.standard

    var showsTraffic: Bool {
        set (value) {
            defaults.set( value, forKey: "showsTraffic" )
        }
        
        get {
            return defaults.bool(forKey: "showsTraffic" )
        }
    }
    
    override private init() {
        super.init()
    }
    
    // A value of nil means to include all routes!
    var routeTypes: [Bool] {
        get {
            let boolArray = defaults.array(forKey: "routeTypes" ) as? [Bool]
            return boolArray ?? Array<Bool>(repeating: true, count: 5)
        }
        
        set (value) {
            defaults.set( value, forKey: "routeTypes" )
            Query.routeTypes = value
        }
    }
    
    var trackUser: Bool {
        set (value) {
            defaults.set( value, forKey: "trackUser" )
        }
            
        get {
            // Note that defaults.bool() returns false if no key exists.
            // Want to default to true if it doesn't exist, so use defaults.object() as? Bool instead.
            return defaults.object(forKey: "trackUser") as? Bool ?? true
        }
    }
    
    //  FAVORITE STOPS
    var favoriteIDs: Set<String> {
        set (value) {
            defaults.set( Array(value), forKey: "favoriteIDs" )
        }

        get {
            let strArray = defaults.stringArray(forKey: "favoriteIDs") ?? Strings.emptyArray
            return Set(strArray)
        }
    }
    
    func addFavorite( stop: Stop ) {
        var favStops = favoriteIDs
        
        favStops.insert(stop.id)
        favoriteIDs = favStops
    }
    
    func removeFavorite( stop: Stop ) {
        var favStops = favoriteIDs
        favStops.remove(stop.id)
        favoriteIDs = favStops
    }
    
    /*
     How to always display favorite stops:
     
     1) Maintain array of favorite stops.
     1a) At startup, initialize list with query of UserSettings.favoriteIDs ids.
     1b) When User adds or removes favorite stop, update array
     2) MapViewController has a list of persistent stops which are not removed when stops are refeshed? 
 */
    
}
