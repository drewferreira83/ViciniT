//
//  Schedule.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 9/8/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit

open class Schedule: HasID {
    public static let Unknown = Schedule()
    
    struct Attributes: Decodable {
        let arrival_time: String
        let departure_time: String
        let drop_off_type: Int
        let pickup_type: Int
        let stop_sequence: Int
        let timepoint: Bool
    }
    
    public let arrival: Date?
    public let departure: Date?
    public let dropOff: GTFS.ScheduledStopType
    public let pickUp: GTFS.ScheduledStopType
    public let stopSequence: Int
    public let timepoint: Bool
    
    public let routeID: String
    public let stopID: String
    public let tripID: String
    
    public let route: Route
    public let stop: Stop
    public let trip: Trip
    
    private init() {
        arrival = nil
        departure = nil
        route = Route.Unknown
        trip = Trip.Unknown
        stop = Stop.Unknown
        
        routeID = Route.Unknown.id
        tripID = Trip.Unknown.id
        stopID = Stop.Unknown.id
        
        dropOff = .none
        pickUp = .none
        stopSequence = -1
        timepoint = false
        
        super.init( id: "schedule.unknown" )
    }
    
    init( source: JXObject, included: [JXObject]? = nil) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Schedule could not extract attributes from JXObject \(source)")
        }
        
        self.arrival = attributes.arrival_time.asDate
        self.departure = attributes.departure_time.asDate
        self.dropOff = GTFS.ScheduledStopType(rawValue: attributes.drop_off_type) ?? .none
        self.pickUp = GTFS.ScheduledStopType(rawValue: attributes.pickup_type) ?? .none
        self.stopSequence = attributes.stop_sequence
        self.timepoint = attributes.timepoint
        
        guard let routeID = source.relatedID(key: .route) else {
            fatalError( "Schedule didn't have routeID. \(source.id)" )
        }
        self.routeID = routeID
        
        guard let stopID = source.relatedID( key: .stop ) else {
            fatalError( "Schedule didn't have stopID. \(source.id)" )
        }
        self.stopID = stopID
        
        guard let tripID = source.relatedID(key: .trip ) else {
            fatalError( "Schedule didn't have tripID. \(source.id)" )
        }
        self.tripID = tripID

        // A query of /schedule might have included data.
        // If the JXObject is part of the included data of a different query,
        // (like /predictions/include=schedule), then the assoicated route/trip/stop object
        // will be nil, but the corresponding ID fields might have valid values.
        
        // Fill in the Stop, Trip, Route and Vehicle from the included data (if it exists).
        // TripID is invalid for Green Line Trains east of Park.
        // Some shuttles or unscheduled trips don't have all of this data.
        if let jxStopData = included?.search(forKind: .stop, id: stopID) {
            stop = Stop( source: jxStopData )
        } else {
            stop = Stop.Unknown
        }
        
        if let jxTripData = included?.search(forKind: .trip, id: tripID) {
            trip = Trip( source: jxTripData )
        } else {
            trip = Trip.Unknown
        }
        
        if let jxRouteData = included?.search( forKind: .route, id: routeID ) {
            route = Route( source: jxRouteData )
        } else {
            route = Route.Unknown
        }

        super.init(id: source.id)
    }
        
        
        
}
