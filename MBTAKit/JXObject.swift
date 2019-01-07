//
//  JXStruct.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/27/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation


// To help with readability...
typealias StringDictionary = [String:String]

struct JXDataBlock: Decodable {
    let data: StringDictionary?
}

struct JXError: Decodable {
    let title: String?
    let status: String?
    let code: String?
    let detail: String?
    let source: StringDictionary?
}

typealias Relationships = [String: JXDataBlock]

// Search functionality on arrays of JXObjects
extension Array where Element == JXObject {
    func search( forKind: GTFS.Kind, id: String? ) -> JXObject? {
        if id == nil {
            return nil
        }
        
        for element in self {
            if element.kind == forKind && element.id == id {
                return element
            }
        }
        
        return nil
    }
}

internal class JXObject: Decodable {
    struct Top: Decodable {
        let jsonapi: StringDictionary?
        let data: [JXObject]?
        let included: [JXObject]?
        let links: StringDictionary?
        let errors: JXError?
    }
    
    enum Keys: String, CodingKey {
        case attributes
        case id
        case type
        case links
        case relationships
    }
    
    let id:String
    let kind: GTFS.Kind
    let links: StringDictionary?
    let relationships: Relationships?
    let attributes: Any?
    

    required init(from decoder: Decoder ) throws {
        let container = try decoder.container(keyedBy: JXObject.Keys.self)
        
        let typeString : String = try! container.decode(String.self, forKey: .type)
        guard let kind = GTFS.Kind(rawValue: typeString) else {
            fatalError( "Unsupported JXObject of kind: \(typeString)")
        }
        
        self.kind = kind
        self.id = try! container.decode(String.self, forKey: .id)
        self.links = try? container.decode(StringDictionary.self, forKey: .links)
        self.relationships = try? container.decode(Relationships.self, forKey: .relationships)
        
        switch kind {
        case .route:
            attributes = try? container.decode(Route.Attributes.self, forKey: .attributes)
        case .trip:
            attributes = try? container.decode( Trip.Attributes.self, forKey: .attributes)
        case .stop:
            attributes = try? container.decode( Stop.Attributes.self, forKey: .attributes)
        case .vehicle:
            attributes = try? container.decode( Vehicle.Attributes.self, forKey: .attributes )
        case .prediction:
            attributes = try? container.decode(Prediction.Attributes.self, forKey: .attributes )
        case .schedule:
            attributes = try? container.decode( Schedule.Attributes.self, forKey: .attributes )
        default:
            fatalError( "Don't know how to interpret \(kind)" )
        }
        
        if attributes == nil {
            Debug.log( "WARNING: JXObject has no attributes. \(self.id)" )
        }
    }

    public func relatedID( key: GTFS.Kind ) -> String? {
        return relationships?[key.rawValue]?.data?["id"]
    }

}
    

    

