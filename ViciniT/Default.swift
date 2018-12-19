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
    }
}

public struct Images {
    public static let favoriteStop24 = UIImage( named: "favorite-24" )
    public static let favoriteStop20 = UIImage( named: "favorite-20" )
    
    public static let stop24 = UIImage( named: "stop-24" )
    public static let stop18 = UIImage( named: "stop-18" )
    public static let stop12 = UIImage( named: "stop-12" )
    public static let stop08 = UIImage( named: "stop-8" )
    
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
    
    // To the user, SUBWAY = (lightRail + subway).  No distinction between the two.
    public enum RouteType: Int, CaseIterable {
        case lightRail
        case subway
        case commuterRail
        case bus
        case ferry
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
    //  The raw values are the thresholds (measured in degrees of latitude in the Boston area,
    //   about 0.02 degrees == 1 mile) used to categorize the span.
    //  NB: Image assignment is in MarkView code.
    public enum Level: Int, CaseIterable {
                        //  Station   Stop
        case closest    //     0       1
        case closer     //     0       2
        case normal     //     1       2
        case farther    //     1       3
        case farthest   //     2   Subway and CR only
    }
    
    public static func level(span: MKCoordinateSpan) -> Level {
        let delta = span.maxDelta
        
        if delta < 0.012 {
            return .closest
        } else if delta < 0.016 {
            return .closer
        } else if delta < 0.020 {
            return .normal
        } else if delta < 0.04 {
            return .farther
        }

        return .farthest
    }
    
    public static func level(region: MKCoordinateRegion) -> Level {
        return( level( span: region.span ) )
    }
}



@IBDesignable extension UIView {
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
}
