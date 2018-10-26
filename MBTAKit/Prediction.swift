//
//  Prediction.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/26/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

open class Prediction: HasID, Comparable {
    
    //  Compare two optional dates.  nil Dates go to the end.
    //       LHS.date     RHS.date      RETURNS
    //          nil         Date         false
    //          nil         nil          true
    //         Date         nil          true
    //         Date         Date         lhs.Date < rhs.Date
    static func datesInOrder( _ lhs: Date?, _ rhs: Date? ) -> Bool {

        if rhs == nil {
            return true
        }
        
        if lhs == nil {
            return false
        }
        
        return lhs! < rhs!
    }
    
    
    // Predictions should be sorted by
    //   a)  route.sortOrder
    //   b)  Direction (0 or 1)
    //   c)  departureTime, but nil goes to end.
    //   d)  arrivalTime
    static public func <(lhs: Prediction, rhs: Prediction) -> Bool {

        // If different routes, then use route.sortOrder
        if lhs.routeID != rhs.routeID {
            return lhs.route.sortOrder < rhs.route.sortOrder
        }
        
        // If different directions on the same route, sort on direction
        if lhs.dir != rhs.dir {
            return lhs.dir < rhs.dir
        }

        // Sorton departure time if they differ.
        if lhs.departure != rhs.departure {
            return Prediction.datesInOrder(lhs.departure, rhs.departure)
        }

        // Order by arrival time.
        return Prediction.datesInOrder( lhs.arrival, rhs.arrival )
    }
    
    public struct Attributes: Decodable {
        let arrival_time: String?
        let departure_time: String?
        let direction_id: Int
        let stop_sequence: Int?
        let status: String?
    }

    public let dir: Int
    public let status: String
    
    // Use this data to create new query if more specific data is needed
    public let routeID: String
    public let stopID: String
    public let tripID: String
    public let scheduleID: String?
    public let vehicleID: String?

    // The route, stop, and trip must be created by looking in the included data of the Top object
    public var route = Route.Unknown
    
    public var stop = Stop.Unknown
    public var trip = Trip.Unknown
    public var schedule = Schedule.Unknown
    public var vehicle: Vehicle?
    
    public var arrival: Date?
    public var departure: Date?
    public var stopSequence: Int
    
    init( source: JXObject, included: [JXObject] ) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Predictions could not extract attributes from JXObject \(source)")
        }

        // Data specific to this prediction
        self.dir = attributes.direction_id
        self.stopSequence = attributes.stop_sequence ?? -1
        self.status = attributes.status ?? ""
        
        // Arrival and departure times.
        // If Arrival is nil, then this is the first stop
        if let datetime = attributes.arrival_time {
            arrival = datetime.asDate
        }
        
        // if Departure is nil, then this is the last stop
        if let datetime = attributes.departure_time {
            departure = datetime.asDate
        }
        
        // PREDICTION object MUST include ROUTE STOP and TRIP ids.
        guard let routeID = source.relatedID( key: .route ) else {
            fatalError( "Prediction didn't have route ID. \(source.id)")
        }
        self.routeID = routeID
        
        guard let stopID = source.relatedID( key: .stop) else {
            fatalError( "Prediction didn't have stop ID. \(source.id)")
        }
        self.stopID = stopID
        
        guard let tripID = source.relatedID( key: .trip ) else {
            fatalError( "Predictions didn't have trip ID. \(source.id)")
        }
        self.tripID = tripID

        // Vehicle & Schedule ID is not required.
        self.vehicleID = source.relatedID(key: .vehicle)
        self.scheduleID = source.relatedID(key: .schedule)

        // Fill in the Stop, Trip, Route and Vehicle from the included data (if it exists).
        // TripID is invalid for Green Line Trains east of Park.
        // Some shuttles or unscheduled trips don't have all of this data.
        if let jxStopData = included.search(forKind: .stop, id: stopID) {
            stop = Stop( source: jxStopData )
        } else {
            fatalError( "Unknown Stop '\(stopID)' for prediction \(source.id)")
        }
        if let jxTripData = included.search(forKind: .trip, id: tripID) {
            trip = Trip( source: jxTripData )
        }
        
        if let jxRouteData = included.search( forKind: .route, id: routeID ) {
            route = Route( source: jxRouteData )
        }
        
        // Vehicle is optional
        if let jxVehicleObject = included.search(forKind: .vehicle, id: vehicleID ) {
            vehicle = Vehicle( source: jxVehicleObject )
        }
        
        if let jxScheduleObject = included.search(forKind: .schedule, id: scheduleID) {
            schedule = Schedule(source: jxScheduleObject)
        }

        super.init( id: source.id )

        if (vehicleID != nil) && (vehicle == nil) {
            // Haven't encountered this...
            Debug.log( "Note:  Prediction has vehicleID, but did not include vehicle data. \(self)")
        }
    }
    
    public var vehicleStatus: String {
        return (vehicle?.status.rawValue ?? "-")
    }

    override public var description: String {
         return "[PRE:\(route.fullName) " +
               "\n  \(status) \(vehicleStatus)]"
    }
}


open class RoutePrediction: HasID {
    public var predictions = [Int: [Prediction]]()
    public let route: Route
    
    init(route: Route) {
        self.route = route
        super.init(id: route.id)
        
        // Two directions
        predictions[0] = [Prediction]()
        predictions[1] = [Prediction]()
    }
    
    public var countBoth: Int {
        return predictions[0]!.count + predictions[1]!.count
    }
    
    public func removelAll() {
        predictions[0]!.removeAll()
        predictions[1]!.removeAll()
    }
    
    public func countOf( direction: Int ) -> Int {
        guard direction == 0 || direction == 1 else {
            fatalError( "Routes only have two directions! \(direction)")
        }

        return predictions[direction]!.count
    }

    public func add( _ prediction: Prediction ) {
        predictions[prediction.dir]!.append( prediction )
    }
    
    public func get( index: Int ) -> Prediction? {
        if index >= predictions[0]!.count {
            return predictions[1]![index - predictions[0]!.count]
        }
        
        return predictions[0]![index]
    }
}

extension Array where Element == RoutePrediction {
    public func search( routeID: String ) -> RoutePrediction? {
        for rp in self {
            if rp.id == routeID {
                return rp
            }
        }
        
        return nil
    }
}
