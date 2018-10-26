//
//  JXVehicle.swift
//  Locality
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

// Wrapper struct to decode JSON returned from a /stops call.
struct JXVehiclesData: Decodable {
    let data: [JXVehicle]?
    let jsonapi: [String:String]
    
    enum CodingKeys: String, CodingKey {
        case data
        case jsonapi
    }
    
    func export() -> [Vehicle] {
        var vehicles = [Vehicle]()
        
        if let jxVehicleData = data {
            for jxVehicle in jxVehicleData {
                vehicles.append( jxVehicle.export() )
            }
        }
        
        return vehicles
    }
}

struct JXVehicle: Decodable {
    struct Attributes: Decodable {
        let bearing: Int?
        let current_status: String
        let current_stop_sequence: Int?
        let direction_id: Int
        let latitude: Double
        let longitude: Double
        let speed: Double?
        // let updated_at: Date
    }
    
     struct RelationshipElement: Decodable {
        let data: [String:String]
    }
    
    struct Relationships: Decodable {
        let route: RelationshipElement
        let stop: RelationshipElement
        let trip: RelationshipElement
    }


    enum CodingKeys: CodingKey {
        case id
        case attributes
        case relationships
        case type
    }
    
    let attributes: Attributes
    let id: String
    let relationships: Relationships
    let type: String
    
    func export() -> Vehicle {
        let coordinate = CLLocationCoordinate2DMake(attributes.latitude, attributes.longitude   )
        let vehicle = Vehicle(id: id, coordinate: coordinate)
        
        vehicle.bearing = attributes.bearing
        vehicle.status = attributes.current_status
        vehicle.stopID = relationships.stop.data[ "id" ]
        vehicle.routeID = relationships.route.data[ "id" ]
        vehicle.tripID = relationships.trip.data[ "id" ]
        return vehicle
    }
}

