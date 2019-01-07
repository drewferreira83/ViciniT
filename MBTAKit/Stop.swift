//
//  Stop.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

// This class is created from data extracted from the MBTA's JSON response.
// This is the data that is available to the outside world in a flatter form.
open class Stop: HasID {
    public static let Unknown = Stop()
    
    // Used to decode JSON only; not storage.
    public struct Attributes: Decodable {
        let address: String?
        let description: String?
        let latitude: Double
        let location_type: Int
        let longitude: Double
        let name: String
        let platform_code: String?
        let platform_name: String?
        let wheelchair_boarding: Int
    }
    
    // REQUIRED
    public let name: String
    public let coordinate: CLLocationCoordinate2D
    
    public let address: String?
    public let descr: String?
    public let locationType: GTFS.LocationType
    public let platformCode: String?
    public let platformName: String?
    public var routeList: NSAttributedString?
    
    fileprivate var _isUnknown = false
    public var isUnknown: Bool {
        return _isUnknown
    }
    
    // Optional
    public var parentID: String?
    
    private init() {
        name = "Unknown Stop"
        coordinate = Default.Map.center
        locationType = .unknown
        address = nil
        descr = "Unknown Stop"
        platformCode = nil
        platformName = nil
        parentID = nil
        _isUnknown = true
        routeList = nil
        super.init(id: "stop.unknown")
        
    }
    
    init( source: JXObject ) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Stop could not get attributes from JXObject. \(source)")
        }

        self.name = Stop.shorten(attributes.name)
        self.coordinate = CLLocationCoordinate2DMake(attributes.latitude, attributes.longitude)
        self.parentID = source.relatedID(key: .parent_station)
      
        // Optional Detailed Information
        self.address = attributes.address
        self.descr = attributes.description
        self.locationType = GTFS.LocationType( rawValue: attributes.location_type) ?? .unknown
        self.platformCode = attributes.platform_code
        self.platformName = attributes.platform_name
        self.routeList = nil
        
        super.init(id: source.id)
    }
    
    public static func arrayFrom( predictions: [Prediction]) -> [Stop] {
        var set = Set<Stop>()
        
        for prediction in predictions {
            set.insert(prediction.stop)
        }
        
        return Array<Stop>(set)
    }

    
    
    
    // These strings occur in stop names.  Abbreviate the name to display accoring to these pairs.
    fileprivate static let abbreviationDictionary: [String: String] = [
        "Commonwealth": "Comm",                 // Generally shorter is better
        "Massachusetts": "Mass",
        "before Manulife Building": "Inbound",  // Silver line
        "after Manulife Building": "Outbound",  // Silver Line
        " - Outbound": "",                      // Some stations make the distinction (Ashmont)
        " - Inbound": "",
        " - to Ashmont/Braintree": "",
        " - to Alewife": "",
        " (Limited Stops)": "",
        "JFK/UMASS Ashmont": "JFK/UMASS",
        "JFK/UMASS Braintree": "JFK/UMASS",
        ", Boston": ""                          // Ferry terminals.  Don't remove ", Hull" because that's important info.
    ]
    
    fileprivate static func shorten( _ string: String ) -> String {
        var workingString = string
        
        for (term, abbreviation) in abbreviationDictionary {
            workingString = workingString.replacingOccurrences(of: term, with: abbreviation)
        }
        
        return workingString
    }

    
}

public func ==(lhs: Stop, rhs: Stop) -> Bool {
    return lhs.id == rhs.id
}


extension Array where Element == Stop {
    func idSet() -> Set<String> {
        var result = Set<String>()
        
        for stop in self {
            result.insert(stop.id)
        }
        
        return result
    }
}

