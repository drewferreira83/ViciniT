//
//  JXPrediction.swift
//  Locality
//
//  Created by Andrew Ferreira on 8/26/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

// Wrapper struct to decode JSON returned from a /stops call.
struct JXPredictionData: Decodable {
    let data: [JXPrediction]?
    let jsonapi: [String:String]
    
    enum CodingKeys: String, CodingKey {
        case data
        case jsonapi
    }
    
    func export() -> [Prediction] {
        var predictions = [Prediction]()
        
        if let jxPredictionData = data {
            for jxPrediction in jxPredictionData {
                predictions.append( jxPrediction.export() )
            }
        }
        
        return predictions
    }
}

struct JXPrediction: Decodable {
    struct Attributes: Decodable {
        let arrival_time: String?
        let departure_time: String?
        let direction_id: Int
        let stop_sequence: Int
    }
    
    struct RelationshipElement: Decodable {
        let data: [String:String]
        
        var id: String {
            return data["id"] ?? ""
        }
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
    
    func export() -> Prediction {

        let prediction = Prediction(id: id,
                                    dir: attributes.direction_id,
                                    routeID: relationships.route.id,
                                    stopID: relationships.stop.id,
                                    tripID: relationships.trip.id)
        
        if let datetime = attributes.arrival_time {
            prediction.arrival = DateFactory.make(datetime: datetime)
        }
        
        if let datetime = attributes.departure_time {
            prediction.departure = DateFactory.make(datetime:datetime)
        }
        
        return prediction
    }
}
