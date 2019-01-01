//
//  Query.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/18/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

/*
 *  .stops
 *    DATA:
 *      String, Stop ID.
 *      CLLocationCoordinate
 *    Returns: Array of Stops
 *
 *  .
 
 */
public protocol QueryListener {
    func receive(query: Query) -> Void
    func dataPendingUpdate( busy: Bool ) -> Void
}


open class Query: Hashable, CustomStringConvertible {
    
    static internal var counter = 0
    static internal let decoder = JSONDecoder()
    static public var activeQueries = Tracker()

    static public var listener: QueryListener!

    // Do not confuse with JXObject.Kind
    public enum Kind: String {
        case alert
        case predictions // Stop
        case routes      // All, ID, or atStop
        case schedules
        case allStopsInRegion       // All stops in a region
        case majorStopsInRegion    // Only CR and Subway
        case trips
        case vehicles     // Trip, Route, or String:vehicleID
        case theseStops   // String: Comma separated list of stop IDs
        case stopsOfRouteType // "0,1" for subway, "2" for CR
        
        case test
        case outstanding  // Check queries that haven't returned.
    }
    
    public let kind: Kind
    public let data: Any?
    public var response: Any?
    
    public var url: URL? = nil
    public var id: Int = -1
    
    public var created: Date = Date()
    public var issued: Date?
    public var received: Date?
    public var serverDate: Date?
    
    init( kind: Kind, data: Any? = nil) {
        self.kind = kind
        self.data = data
        self.id = Query.counter
        Query.counter += 1
    }
    
    public var hashValue: Int {
        return id
    }
    
    public var statusDescription: String {
        if let timestamp = received {
            return( "Received \(timestamp.withms())")
        } else if let timestamp = issued {
            return( "Issued   \(timestamp.withms())")
        }
        
        return(     "Created  \(created.withms())")
    }
    
    public var description: String {
        return( "Q[\(kind)] \(statusDescription)")
    }
    
    public var isPending: Bool {
        return received == nil
    }

    // The URL is used to distinguish queries
    static public func == ( lhs: Query, rhs: Query ) -> Bool {
        return lhs.url == rhs.url
    }
    
    static public func != (lhs: Query, rhs: Query) -> Bool {
        return lhs.url != rhs.url
    }
    
    
    // Issue the query
    @discardableResult public func resume() -> Bool {
        
        if let url = Query.makeURL(query: self) {
            Debug.log( " -> \(self)", flag: .important)
            //Debug.log( url.relativeString )

            // Update and track Query.
            issued = Date()
            Query.activeQueries.track(query: self)
            Query.listener.dataPendingUpdate(busy: true)

            // Create and issue request.
            URLSession.shared.dataTask(with: url, completionHandler: MBTAresponseHandler).resume()
            return( true )
        }
        
        fatalError( "MURL Error!  \(self)")
    }
    
}
