//
//  ResponseHandler
//  ViciniT
//
//  Created by Andrew Ferreira on 8/20/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

extension ViciniT {

    // NEVER ON THE MAIN THREAD!!!!
    public func process(query: Query) {
        Debug.log( "<-  \(query)", flag: .important )
       // Debug.log( query.url!.relativeString )
        
        switch query.kind {
            /*
        case .test:
            guard let stops = query.response as? [Stop] else {
                fatalError( "/stops returned something unexpected.")
            }

            guard let region = query.data as? MKCoordinateRegion else {
                fatalError( "/stops didn't have a MKCoordinateRegion. \(query)" )
            }

            let center = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            print( "Center point: (\(center.coordinate.latitude), \(center.coordinate.longitude))")
            for stop in stops {
                let stopLocation = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude)
//                print( "   (\(stopLocation.coordinate.latitude), \(stopLocation.coordinate.longitude)) --->  \(center.distance(from: stopLocation))")
                
                print( "  \(stop.name) -->  \(center.distance(from: stopLocation))")
            }
 */

        case .allStopsInRegion, .majorStopsInRegion:
            guard let stops = query.response as? [Stop] else {
                fatalError( "/stops returned something unexpected.")
            }

            guard let region = query.data as? MKCoordinateRegion else {
                fatalError( "/stops didn't have a MKCoordinateRegion. \(query)" )
            }

            var marks = [Mark]()
            for stop in stops {
                // Ignore child stations.
                if stop.parentID == nil && region.contains(stop.coordinate) {
                    marks.append(Mark(stop: stop ))
                }
            }
                        
            // Does not change region, does not select anything. Doesn't affect any vehicles.
            map.display(marks: marks, kind: .stop, select: nil )
            
        case .theseStops:
            // This will reset the
            guard let stops = query.response as? [Stop] else {
                fatalError( ".theseStops returned something unexpected." )
            }
            
            var marks = [Mark]()
            for stop in stops {
                // Ignore child stations.
                if stop.parentID == nil {
                    marks.append( Mark(stop: stop) )
                }
            }
            
            // GOAL: Create MKCoordinateRegion that includes all stops.

            // If we don't know the user location, update range to show all favorite stops.

            // Create a temporary array of coordinates
            var coords = [CLLocationCoordinate2D]()
            
            for stop in stops {
                coords.append( stop.coordinate )
            }
            
            // Get the extrema for the lat and lng
            let minLat = coords.min { $0.latitude < $1.latitude }!.latitude
            let maxLat = coords.max { $0.latitude < $1.latitude }!.latitude
            let minLon = coords.min { $0.longitude < $1.longitude }!.longitude
            let maxLon = coords.max { $0.longitude < $1.longitude }!.longitude
//            var span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
            
            // Make sure the span isn't too small and add a small border.
//            span.latitudeDelta = max( span.latitudeDelta, Default.Map.span.latitudeDelta ) + 0.01
//            span.longitudeDelta = max( span.longitudeDelta, Default.Map.span.longitudeDelta ) + 0.01
            
            let center = CLLocationCoordinate2D(latitude: minLat + (maxLat - minLat) / 2,
                                                longitude: minLon + (maxLon - minLon) / 2)
//            let region = MKCoordinateRegion(center: center, span: span)
            
            let userLocation = map.getUserLocation() ?? center
            let closestMark = marks.closest(to: userLocation)
            
            map.display(marks: marks, kind: .stop, select: closestMark)
        
        case .routes:
            guard let routes = query.response as? [Route] else {
                Debug.log("/routes returned something unexpected.")
                return
            }
            
            // If these routes are for a particular stop, then display the routes.
            if let stop = query.data as? Stop {
                map.show(routes: routes, for: stop)
                return
            }
            
            fatalError( "Got /Routes, but didn't have associated stop. \(query)" )
            
        case .vehicles:
            guard let vehicles = query.response as? [Vehicle] else {
                fatalError( "/vehicles returned something unexpected." )
            }

            var marks = [Mark]()
            for vehicle in vehicles {
                marks.append( Mark(vehicle: vehicle ) )
            }
            
            map.display(marks: marks, kind: .vehicle, select: nil)

        case .predictions:
            guard let predictions = query.response as? [Prediction] else {
                fatalError( "/predictions returned something unexpected. \(query)")
            }
            
            if let stop = query.data as? Stop {
                //  TODO:  Post message to user.
                if predictions.isEmpty {
                    Debug.log( "No predictions for \(stop.name)" )
                    break
                }
                
                let sorted = predictions.sorted()
                map.show( predictions: sorted, for: stop )
            }
            
        case .stopsOfRouteType:
            guard let stops = query.response as? [Stop] else {
                fatalError( "/stopsOfRoutType returned something unexpected. \(query)")
            }
            
            guard let filter = query.data as? String else {
                fatalError( "Can't interpret filter for .stopsOfRouteType. \(query)" )
            }
            
            var idSet = Set<String>()
            
            for stop in stops {
                if stop.parentID == nil {
                    idSet.insert( stop.id )
                }
            }
            
            switch filter {
            case MBTA.stopType.subway:
                Session.subwayStopIDs = idSet
                
            case MBTA.stopType.commRail:
                Session.commRailIDs = idSet
                
            case MBTA.stopType.ferry:
                Session.ferryIDs = idSet
                
            default:
                fatalError( "Don't know filter for .stopsOfRouteType. \(query)" )
            }
            
        default:
            Debug.log( "Don't know what to do with Query \(query.kind)")
        }
    }
  
}

