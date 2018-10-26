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
internal class MURL {
    // Unprocessed MBTA URL looks like
    // https://api-v3.mbta.com/  stops     ?api_key=123   &filter[latitude]=42.3601    &filter[longitude]=-71.0589
    //  URL_HEAD +              Command +   MBTA_KEY     { + Filter                      + Filter ...  }
   
    // Command one of: vehicles, trips, stops, schedules, routes, predictions, alerts
    
    static let URL_HEAD = "https://api-v3.mbta.com"
    static let MBTA_KEY = "?api_key=0de754c34a1445aeac7cbc2c385ef0ae"
    
    static func makeURL(query: Query) -> URL? {
        var baseString: String = URL_HEAD
        
        switch ( query.kind )
        {
        case .stop:
            // Single Stop
            guard let stopID = query.data as? String else {
                fatalError( "Stop Query requires a valid list of stop IDs. \(String(describing:query.data))" )
            }

            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
            baseString.append( "&include=parent_station" )
            baseString.append( "&filter[id]=\(stopID.forURL)")

        case .favoriteStops:
            guard let idArray = query.data as? [String] else {
                fatalError( "FavoriteStops query requires an array of stop IDs  \(String(describing:query.data))" )
            }

            guard !idArray.isEmpty else {
                fatalError( "FavoriteStops query requires at least one stop ID" )
            }
            
            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
            baseString.append( "&include=parent_station" )
            baseString.append( "&filter[id]=\(idArray.joined(separator: ","))")

/*
        case .test:
            baseString =
            "https://api-v3.mbta.com/stops?filter[latitude]=42.351074&filter[longitude]=-71.065126&filter[route_type]=0,1,4&page[limit]=7"
 
 */
        case .allStopsInRegion, .majorStopsInRegion:
            guard let region = query.data as? MKCoordinateRegion else {
                fatalError( "StopsInRegion query requires a region. \(String( describing: query.data ))")
            }
            
            baseString.append( "/stops")
            baseString.append( MBTA_KEY )
           // baseString.append( "&sort=location_type" )
            baseString.append( "&include=parent_station" )
            
            if query.kind == .majorStopsInRegion {
                baseString.append( "&filter[route_type]=0,1,2" )
            }

            let center = region.center
            let radius = region.span.maxDelta

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
            
            if let routeID = query.data as? String {
                baseString.append( "&filter[id]=\(routeID.forURL)" )
                break
            }
            
            if let stop = query.data as? Stop {
                baseString.append( "&filter[stop]=\(stop.id.forURL)")
                break
            }

            if query.data != nil {
                fatalError( "Routes query has unexpected data. \(query)")
            }
            
        case .trips:
            baseString.append( "/trips" )
            baseString.append( MBTA_KEY)

            // Trips take a tripID.
            if let tripID = query.data as? String {
                baseString.append( "&filter[id]=\(tripID.forURL)")
                break
                
            }
            
            if let route = query.data as? Route {
                baseString.append( "&filter[route]=\(route.id.forURL)" )
                break
            }
            
            fatalError( "Trips query requires an ID or Route. data=\(String(describing:query.data))")
            
        case .vehicles:
            baseString.append( "/vehicles" )
            baseString.append( MBTA_KEY)

            // No data means get all.
            if query.data == nil {
                break
            }
            
            // Valid parameters are Route and Vehicle ID
            if let route = query.data as? Route {
                baseString.append( "&filter[route]=\(route.id.forURL)")
                break
            }
            
            if let id = query.data as? String {
                baseString.append( "&filter[id]=\(id.forURL)")
                break
            }
            
            if let trip = query.data as? Trip {
                baseString.append( "&filter[trip]=\(trip.id.forURL)" )
            }

            fatalError( "Vehicle Query requires an ID, Route, or Trip.  data=\(String(describing: query.data))")
            
        case .predictions:
            baseString.append("/predictions")
            baseString.append( MBTA_KEY )
            //baseString.append( "&sort=departure_time,arrival_time")
            baseString.append( "&include=route,stop,trip,vehicle,schedule" )

            if let stop = query.data as? Stop {
                baseString.append( "&filter[stop]=\(stop.id.forURL)")
                
            } else if let coords = query.data as? CLLocationCoordinate2D {
                baseString.append( "&filter[latitude]=\(coords.latitude)" )
                baseString.append( "&filter[longitude]=\(coords.longitude)" )
//                baseString.append( "&filter[radius]=0.01" )
                
            } else {
                fatalError( "Prediction Query requires Stop. data=\(String(describing:query.data))")
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
