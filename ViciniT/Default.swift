//
//  Default.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit
import UIKit

public struct Default {
    public struct Map {
        public static let span = MKCoordinateSpan.init( latitudeDelta: 0.01, longitudeDelta: 0.01)
        public static let center = CLLocationCoordinate2DMake( 42.36, -71.06 )  // Boston
        public static let region = MKCoordinateRegion.init(center: Map.center, span: Map.span)
    }
    
    public struct Font {
        public static let normal = UIFont.systemFont( ofSize: 15 )
        
        public static let forPredictionHeader = UIFont.systemFont(ofSize: 17, weight: .bold )
        public static let forStatus = UIFont.italicSystemFont(ofSize: 12)
        public static let forDirection = UIFont.systemFont(ofSize: 15)
        public static let forTime = UIFont.systemFont(ofSize: 17, weight: .bold)
        public static let forCalloutSubtitle = UIFont.systemFont(ofSize: 14, weight: .bold)
        
        public static let monospaced = UIFont(name: "Courier New", size: 12) ?? UIFont.systemFont(ofSize: 12)
    }
 
    public struct Location {
        public static let BOSTON = CLLocationCoordinate2D( latitude: 42.36, longitude: -71.062)
        public static let DAVIS = CLLocationCoordinate2D( latitude: 42.40, longitude: -71.122299)
        public static let manager = CLLocationManager()
        public static var accessible: Bool {
            return CLLocationManager.locationServicesEnabled() &&
                (CLLocationManager.authorizationStatus() == .authorizedAlways ||
                 CLLocationManager.authorizationStatus() == .authorizedWhenInUse)
        }
    }
    
}

public struct Images {
    public static let favoriteStop24 = UIImage( named: "favorite-24" )
    public static let favoriteStop20 = UIImage( named: "favorite-20" )
    
    public static let stop24 = UIImage( named: "stop-24" )
    public static let stop18 = UIImage( named: "stop-18" )
    public static let stop12 = UIImage( named: "stop-12" )
    public static let stop08 = UIImage( named: "stop-8" )
    public static let stopRail12 = UIImage( named: "stopRail-12" )
    
    public static let vehicle24 = UIImage( named: "vehicle-24" )
    public static let vehicle18 = UIImage( named: "vehicle-18" )
    public static let vehicle12 = UIImage( named: "vehicle-12" )
    public static let vehicle10 = UIImage( named: "vehicle-10" )
    
    public static let favoriteTrue = UIImage( named: "barButton.favorite.true" )
    public static let favoriteFalse = UIImage( named: "barButton.favorite.false" )
    
    public static let subwayTrue = UIImage( named: "button.subway.true" )
    public static let subwayFalse = UIImage( named: "button.subway.false" )
    public static let commRailTrue = UIImage( named: "button.commRail.true" )
    public static let commRailFalse = UIImage( named: "button.commRail.false" )
    public static let busTrue = UIImage( named: "button.bus.true" )
    public static let busFalse = UIImage( named: "button.bus.false" )
}

public typealias AttrDict = [NSAttributedString.Key: Any]

public struct Colors {
    public struct Times {
        public static let normal: AttrDict = [NSAttributedString.Key.foregroundColor: UIColor(hex: "008000")]
        public static let soon: AttrDict = [NSAttributedString.Key.foregroundColor: UIColor.orange]
        public static let now: AttrDict = [NSAttributedString.Key.foregroundColor: UIColor.red]
        public static let old: AttrDict = [NSAttributedString.Key.foregroundColor: UIColor.gray]
    }
}

public struct Strings {
    public static let NBSP = "\u{00a0}"
    public static let emptyArray = [String]()
}

public struct Session {
    public static var zoomInForBuses = false
    
    public static var subwayStopIDs = Set<String>()
    public static var commRailIDs = Set<String>()
    public static var ferryIDs = Set<String>()
}
