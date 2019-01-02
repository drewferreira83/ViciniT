//
//  MURL.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/17/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

// TODO:  This can be made into Query extension.
extension Query {
    // Unprocessed MBTA URL looks like
    // https://api-v3.mbta.com/  stops     ?api_key=123   &filter[latitude]=42.3601    &filter[longitude]=-71.0589
    //  URL_HEAD +              Command +   MBTA_KEY     { + Filter                      + Filter ...  }
   
    // Command one of: vehicles, trips, stops, schedules, routes, predictions, alerts
    
    static let URL_HEAD = "https://api-v3.mbta.com"
    static let MBTA_KEY = "?api_key=0de754c34a1445aeac7cbc2c385ef0ae"
    
    // Define major route types to be Subway and Commuter Rail.
    static let majorRouteTypes: [Bool] = [true, true, true, false, false]
    static let allRouteTypes: [Bool] = [true, true, true, true, true]

    // GTFS route type is used as the index, true to include, false to ignore.
    //  e.g. [F,F,T,F,F] means Commuter Rail only. (index 2 = GTFS.RouteType = CommuterRail)
    // Start with including all route types
    static var routeTypes = Query.allRouteTypes
    
    static func makeURL(query: Query) -> URL? {
        var baseString: String = URL_HEAD
        
        // Make a route filter if set
     //   var typeFilterString = ""
        
        switch ( query.kind )
        {

        case .theseStops:
            var filterString: String!
            
            guard query.pData != nil else {
                fatalError( "TheseStops requires a parameter" )
            }
            
            if let idArray = query.pData as? [String] {
                filterString = "&filter[id]=\(idArray.joined(separator: ","))"
            } else if let route = query.pData as? Route {
                filterString = "&filter[route]=\(route.id)"
            } else {
                fatalError( "TheseStops takes an array of stopID strings or a Route" )
            }
            

            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
            baseString.append( "&include=parent_station" )
            baseString.append( filterString )
            
        
        case .stopsOfRouteType:
            guard let routeTypesList = query.pData as? String else {
                fatalError( "StopsOfType query requires a string \(String(describing:query.pData))" )
            }
            
            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
            baseString.append( "&include=parent_station" )
            baseString.append( "&filter[route_type]=\(routeTypesList)")

/*
        case .test:
            baseString =
            "https://api-v3.mbta.com/stops?filter[latitude]=42.351074&filter[longitude]=-71.065126&filter[route_type]=0,1,4&page[limit]=7"
 
 */
        case .allStopsInRegion, .majorStopsInRegion:
            guard let region = query.pData as? MKCoordinateRegion else {
                fatalError( "StopsInRegion query requires a region. \(String( describing: query.pData ))")
            }
            
            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
            baseString.append( "&include=parent_station" )
            
            // Determine route_type filter

            let majorFilter = (query.kind == .majorStopsInRegion) ? Query.majorRouteTypes : Query.allRouteTypes
            var validTypes = [String]()
                
            for i in 0 ..< routeTypes.count {
                if routeTypes[i] && majorFilter[i] {
                    validTypes.append( String(i) )
                }
            }

            if !validTypes.isEmpty {
                baseString.append( "&filter[route_type]=\(validTypes.joined( separator: "," ))" )
            }

            let center = region.center
            let radius = region.span.maxDelta * 0.55 // dividing by 2 didn't get edge cases.

            baseString.append( "&filter[latitude]=\(center.latitude)" )
            baseString.append( "&filter[longitude]=\(center.longitude)" )
            baseString.append( "&filter[radius]=\(radius)" )
            
        case .routes:
            // If Data is nil, return all routes
            // If Data is a string, return route with that ID
            // if Data is a stop, return routes at that stop
            baseString.append( "/routes" )
            baseString.append( MBTA_KEY )
            baseString.append("&sort=sort_order")
            
            if let routeID = query.pData as? String {
                baseString.append( "&filter[id]=\(routeID.forURL)" )
                break
            }
            
            if let stop = query.pData as? Stop {
                baseString.append( "&filter[stop]=\(stop.id.forURL)")
                break
            }

            if query.pData != nil {
                fatalError( "Routes query has unexpected data. \(query)")
            }
            
        case .trips:
            baseString.append( "/trips" )
            baseString.append( MBTA_KEY)

            // Trips take a tripID.
            if let tripID = query.pData as? String {
                baseString.append( "&filter[id]=\(tripID.forURL)")
                break
                
            }
            
            if let route = query.pData as? Route {
                baseString.append( "&filter[route]=\(route.id.forURL)" )
                break
            }
            
            fatalError( "Trips query requires an ID or Route. data=\(String(describing:query.pData))")
            
        case .vehicles:
            baseString.append( "/vehicles" )
            baseString.append( MBTA_KEY)

            // No data means get all.
            if query.pData == nil {
                break
            }
            
            // Include stop, trip, and route information for more specific queries
            baseString.append( "&include=stop,trip,route" )

            
            // Valid parameters are Route, Trip, or Vehicle ID
            if let route = query.pData as? Route {
                baseString.append( "&filter[route]=\(route.id.forURL)")
                break
            }
            
            if let id = query.pData as? String {
                baseString.append( "&filter[id]=\(id.forURL)")
                break
            }
            
            if let trip = query.pData as? Trip {
                baseString.append( "&filter[trip]=\(trip.id.forURL)" )
                break
            }

            fatalError( "Vehicle Query requires an ID, Route, or Trip.  data=\(String(describing: query.pData))")
            
        case .predictions:
            baseString.append("/predictions")
            baseString.append( MBTA_KEY )
            //baseString.append( "&sort=departure_time,arrival_time")
            baseString.append( "&include=route,stop,trip,vehicle,schedule" )

            if let stop = query.pData as? Stop {
                baseString.append( "&filter[stop]=\(stop.id.forURL)")
                
            } else if let coords = query.pData as? CLLocationCoordinate2D {
                baseString.append( "&filter[latitude]=\(coords.latitude)" )
                baseString.append( "&filter[longitude]=\(coords.longitude)" )
//                baseString.append( "&filter[radius]=0.01" )
                
            } else {
                fatalError( "Prediction Query requires Stop. data=\(String(describing:query.pData))")
            }
            
        default:
            fatalError( "Unsupported query: \(query.kind)" )
        }
        
        
        guard let url = URL( string: baseString ) else {
            fatalError( "Failed to create URL from \(baseString)" )
        }
        
        query.url = url
        
        return  url
        
    }
    
}

extension String {
    // Some fields have spaces and other characters that need to be encoded to be in an URL.
    var forURL: String {
        return self.addingPercentEncoding( withAllowedCharacters: .urlQueryAllowed) ?? "error"
    }
}

extension MKCoordinateSpan {
    // Return the larger of the width or height of the region.
    public var maxDelta: Double {
        return max( self.latitudeDelta, self.longitudeDelta )
    }
}
