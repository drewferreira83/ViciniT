//
//  Query Utilities.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 9/22/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

extension Query {
    func MBTAresponseHandler( _ data: Data?, response: URLResponse?, error: Error? ) -> Void {
        guard error == nil else {
            Debug.log( "Handler got error \(error!.localizedDescription)")
            return
        }
        guard let data = data else {
            Debug.log( "No Data in handler?")
            return
        }

        received = Date()
        
        /*
        // Determine server time
         // NOT SURE IF THIS MATTERS!  Might be significant if client time is different from server time.
        if let resp = response as? HTTPURLResponse {
            if let serverDateString = resp.allHeaderFields["Date"] as? String {
                serverDate = serverDateString.asInternetDate
            }
        }
        */
 
        let jxTop = try! Query.decoder.decode(JXObject.Top.self, from: data)
        
        guard jxTop.errors == nil else {
            fatalError( "Error reported: \(jxTop.errors!)")
        }
        
        guard let jxTopData = jxTop.data else {
            fatalError( "Decoder got no data." )
        }
        
        switch (kind) {
            
        case .allStopsInRegion, .majorStopsInRegion, .theseStops, .stopsOfRouteType, .test:
            var stops = [Stop]()
            
            // Create the stops in the data block.
            for element in jxTopData {
                let newStop = Stop( source: element )
                if newStop.locationType == .station || newStop.locationType == .stop {
                    stops.append( newStop )
                }
            }
            
            // Create the stops in the included block (if any)
            if let included = jxTop.included {
                for element in included {
                    let newStop = Stop( source: element )
                    if newStop.locationType == .station || newStop.locationType == .stop {
                        stops.append( newStop )
                    }
                }
            }
            
            self.response = stops
            
        case .routes:
            var routes = [Route]()
        
            for element in jxTopData {
                routes.append( Route(source: element) )
            }
            
            self.response = routes
            
        case .vehicles:
            var vehicles = [Vehicle]()
            
            for element in jxTopData {
                if element.attributes == nil {
                    Debug.log( "No Attributes for vehicle \(element.id)")
                    continue
                }
                vehicles.append( Vehicle( source: element, included: jxTop.included ) )
            }
            
            self.response = vehicles
            
        case .predictions:
            var predictions = [Prediction]()
        
            // This query might return nothing which is fine.
            if !jxTopData.isEmpty {
                guard let included = jxTop.included else {
                    fatalError( "Prediction request did not have included data. \(jxTop)")
                    break
                }
                
                for element in jxTopData {
                    let prediction = Prediction( source: element, included: included )
                    predictions.append( prediction )
                }
            }
            self.response = predictions
            
        default:
            fatalError( "MBTAKit Receiver doesn't know how to handle Query \(kind)")
        }
        
        Query.activeQueries.remove( query: self )
        Query.listener.receive(query: self)
        Query.listener.dataPendingUpdate(busy: !Query.activeQueries.isEmpty)
    }

    open class Tracker {
        private var queries = Set<Query>()
        
        var count: Int {
            return queries.count
        }
        
        var isEmpty: Bool {
            return queries.isEmpty
        }
        
        func contains( query: Query ) -> Bool {
            return queries.contains( query )
        }
        
        func track( query: Query ) {
            queries.insert( query )
        }
        
        func find( matchingUrl: URL, andRemove: Bool = false ) -> Query? {
            for query in queries {
                if query.url == matchingUrl {
                    if andRemove {
                        remove( query: query )
                    }
                    return query
                }
            }
            
            return nil
        }
        
        func remove( query: Query ) {
            queries.remove( query)
        }
        
        func removeAll() {
            queries.removeAll(keepingCapacity: false)
        }
        
        // This returns queries that are over the specified timeout.  This does not remove them.
        func overdue( timeout: TimeInterval ) -> [Query] {
            var overdueQueries = [Query]()
            
            for query in queries {
                guard let issued = query.issued else {
                    continue
                }
                
                if issued.timeIntervalSinceNow > timeout {
                    overdueQueries.append(query)
                }
            }
            
            return overdueQueries
        }
    }
}
