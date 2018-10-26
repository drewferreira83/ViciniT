//
//  JXTrip.swift
//  Locality
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

struct JXTripsData: Decodable {
    let data: [JXTrip]?
    let jsonapi: [String: String]
    
    func export() -> [Trip] {
        var trips = [Trip]()
        
        if let jxTrips = data {
            for jxTrip in jxTrips {
                trips.append(jxTrip.export())
            }
        }
        
        return trips
    }
}

struct JXTrip: Decodable {
    struct Attributes: Decodable {
        let block_id: String
        let direction_id: Int
        let headsign: String
        let name: String
        let wheelchair_accessible: Int
    }
    
    
    struct RelationshipElement: Decodable {
        let data: [String:String]
    }
    
    struct Relationships: Decodable {
        let route: RelationshipElement
        let service: RelationshipElement
        let shape: RelationshipElement
    }
    

    let id: String
    let attributes: Attributes
    let relationships: Relationships
    
    enum CodingKey {
        case id
        case attributes
        case relationships
    }
    
    func export() -> Trip {
        let trip = Trip(id: id, dir: attributes.direction_id, routeID: relationships.route.data["ID"], headsign: attributes.headsign, accessible: attributes.wheelchair_accessible)
        return trip
    }
}
