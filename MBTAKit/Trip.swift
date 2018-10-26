//
//  Trip.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

public class Trip: HasID {
    public static let Unknown = Trip()
    
    let dir: Int
    let headsign: String
    let accessible: Int
    let name: String
    
    let routeID: String
    var route: Route!
    
    struct Attributes: Decodable {
        let block_id: String?
        let direction_id: Int
        let headsign: String
        let name: String
        let wheelchair_accessible: Int
    }
    
    private var _isUnknown = false
    public var isUnknown: Bool {
        return _isUnknown
    }

    private init() {
        dir = 2
        headsign = "Unknown Trip"
        accessible = -1
        name = "Unknown Trip"
        routeID = "UnknownTrip.RouteID"
        route = Route.Unknown
        _isUnknown = true
        super.init(id:"trip.unknown")
    }

    
    init( source: JXObject ) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Trip could not interpret attributes. \(source) ")
        }
        
        self.dir = attributes.direction_id
        self.headsign = attributes.headsign
        self.accessible = attributes.wheelchair_accessible
        self.name = attributes.name
        
        guard let routeID = source.relatedID( key: .route ) else {
            fatalError( "Trip source did not have Route ID. \(source)")
        }
        self.routeID = routeID
        
        super.init(id:source.id)
    }
    
    override public var description: String {
        return( "[Trip: id=\(id), dir=\(dir), headsign=\(headsign), accessible=\(accessible)]")
    }
}
