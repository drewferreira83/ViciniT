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
    
    public struct Images {
        public static let favoriteStop = UIImage( named: "favorite-24" )
        public static let stop24 = UIImage( named: "stop-24" )
        public static let stop18 = UIImage( named: "stop-18" )
        public static let stop12 = UIImage( named: "stop-12" )
        
        public static let favoriteTrue = UIImage( named: "favoriteTrue-26" )
        public static let favoriteFalse = UIImage( named: "favoriteFalse-26" )
        public static let vehicle24 = UIImage( named: "vehicle-24" )
        public static let vehicle12 = UIImage( named: "vehicle-12" )
    }
    
    public struct Location {
        public static let BOSTON = CLLocationCoordinate2D( latitude: 42.36, longitude: -71.062)
        public static let DAVIS = CLLocationCoordinate2D( latitude: 42.40, longitude: -71.122299)
    }
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

public struct GTFS {
    // These are the keys to the GTFS data structures
    public enum Kind: String {
        case route, stop, trip, vehicle, prediction, schedule, parent_station
        // service, shape, child_stops
    }
    
    public enum RelationshipKey: String {
        case parent_station
        case child_stops
    }

    public enum LocationType: Int {
        case unknown = -1  // Extension
        case stop = 0
        case station = 1
        case entrance = 2
    }
    
    // Wheelchair boarding in GTFS
    public enum Accessibility: Int {
        case unknown = 0
        case accessible = 1
        case notAccessible = 2
    }
    
    // Valid values in GTFS 
    public enum VehicleStatus: String {
        case incoming = "INCOMING_AT"      // Approaching station
        case stopped = "STOPPED_AT"        // At station
        case inTransit = "IN_TRANSIT_TO"   // Departed previous station
        
        case unknown = "unknown"
    }

    // What to display for the previous statuses.
    public static let VehicleStatusDescription: [VehicleStatus: String] = [
        VehicleStatus.incoming: "Incoming",
        VehicleStatus.stopped: "Stopped at",
        VehicleStatus.inTransit: "In Transit to" ]
    
    //  https://github.com/google/transit/blob/master/gtfs/spec/en/reference.md#stop_timestxt
    public enum ScheduledStopType: Int {
        case regular = 0
        case none = 1
        case contactAgency = 2
        case contactDriver = 3
    }
  
}

extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        guard let rgb = UInt(hex, radix: 16) else {
            fatalError( "Expected a hex value for a color.  Got \(hex)")
        }
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
    func lighten() -> UIColor {
        //  Map the RGB values proportionately to [low...1.0]
        let low: CGFloat = 220 / 255
        let range: CGFloat  = 1 - low
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let newR = low + range * r
        let newG = low + range * g
        let newB = low + range * b
        
        return( UIColor(red: newR, green: newG, blue: newB, alpha: a))
        
    }

}

public struct Scope {
    //  The raw values are the thresholds used to categorize the span.
    public enum Level: Double {
        case high = 0.06
        case medium = 0.04
        case normal = 0.00
        case unset = -1.0
    }
    
    public static func level(span: MKCoordinateSpan) -> Level {
        if span.maxDelta > Level.high.rawValue {
            return .high
        } else if span.maxDelta > Level.medium.rawValue {
            return .medium
        }
        return .normal
    }
    
    public static func level(region: MKCoordinateRegion) -> Level {
        return( level( span: region.span ) )
    }
}
