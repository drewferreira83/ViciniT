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
    
    struct MapOptions: Codable {
        private var _mapTypeRawValue: UInt = 0
        var mapType: MKMapType {
            get {
                return MKMapType( rawValue: _mapTypeRawValue ) ?? .standard
            }
            
            set (value) {
                _mapTypeRawValue = value.rawValue
            }
        }

        var showsPointsOfInterest = true
        var showsBuildings        = true
        var showsScale            = true
        var showsTraffic          = true
        var shows3DView           = false
        var allowsRotation        = false
    }

    private var defaults = UserDefaults.standard

    var mapOptions: MapOptions {
        set (value) {
            defaults.set( value, forKey: "mapOptions" )
        }
        
        get {
            return (defaults.object( forKey: "mapOptions" ) as? MapOptions) ?? MapOptions()
        }
    }
    
    override private init() {
        super.init()
    }
    
    // A value of nil means to include all routes!
    var routeTypes: [Bool]? {
        get {
            return defaults.array(forKey: "routeTypes" ) as? [Bool]
        }
        
        set (value) {
            defaults.set( value, forKey: "routeTypes" )
        }
    }
    
    var favoriteStops: Set<String> {
        set (value) {
            defaults.set( Array(value), forKey: "favoriteStops" )
        }

        get {
            let strArray = defaults.stringArray(forKey: "favoriteStops") ?? Strings.emptyArray
            return Set(strArray)
        }
    }
    
    func addFavorite( stop: Stop ) {
        var favStops = favoriteStops
        
        favStops.insert(stop.id)
        favoriteStops = favStops
    }
    
    func removeFavorite( stop: Stop ) {
        var favStops = favoriteStops
        favStops.remove(stop.id)
        favoriteStops = favStops
    }
    
}
