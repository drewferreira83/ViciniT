//
//  Vehicle.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

open class Vehicle: HasID {
    public static let Unknown = Vehicle()
    
    struct Attributes: Decodable {
        let bearing: Int?
        let current_status: String
        let current_stop_sequence: Int?
        let direction_id: Int?
        let label: String?
        let latitude: Double
        let longitude: Double
        let speed: Double?
        let updated_at: String?
    }
    
    public let coordinate: CLLocationCoordinate2D

    public var directionID: Int?
    public var bearing: Int?
    public var status: GTFS.VehicleStatus
    public var speed: Double?
    public var stopSequence: Int?
    public var updated: Date?
    
    public var routeID: String?
    public var stopID: String?
    public var tripID: String?
    
    public var route: Route?
    public var stop: Stop?
    public var trip: Trip?

    private var _isUnknown = false
    public var isUnknown: Bool {
        return _isUnknown
    }
    
    private init() {
        self.coordinate = Default.Map.center
        self.directionID = nil
        self.bearing = nil
        self.status = .unknown
        self.speed = nil
        self.stopSequence = nil
        self.updated = nil
        self.routeID = nil
        self.stopID = nil
        self.tripID = nil
        self.route = Route.Unknown
        self.stop = Stop.Unknown
        self.trip = Trip.Unknown
        self._isUnknown = true
        super.init( id: "vehicle.unknown" )
    }
    
    init( source: JXObject ) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Vehicle couldn't interpret attributes. \(source)")
        }
        
        self.coordinate = CLLocationCoordinate2DMake(attributes.latitude, attributes.longitude)
        self.directionID = attributes.direction_id
        self.bearing = attributes.bearing
        self.status = GTFS.VehicleStatus( rawValue: attributes.current_status ) ?? .unknown
        self.stopSequence = attributes.current_stop_sequence
        if let datetime = attributes.updated_at {
            self.updated = datetime.asDate
        }
        
        self.routeID = source.relatedID(key: .route)
        self.stopID = source.relatedID(key: .stop)
        self.tripID = source.relatedID(key: .trip)
        
        super.init( id: source.id )
    }
}
