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
                fatalError( "/test returned something unexpected.")
            }

            var minLat = 90.0, maxLat = 0.0, minLon = 0.0, maxLon = -180.0
            for stop in stops {
                minLat = min( minLat, stop.coordinate.latitude )
                maxLat = max( maxLat, stop.coordinate.latitude )
                minLon = min( minLon, stop.coordinate.longitude)
                maxLon = max( maxLon, stop.coordinate.longitude)
            }

            print( minLat, maxLat, minLon, maxLon )
 */
            
        case .allStopsInRegion, .majorStopsInRegion:
            guard let stops = query.response as? [Stop] else {
                fatalError( "/stops returned something unexpected.")
            }

            guard let region = query.pData as? MKCoordinateRegion else {
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
            guard let stops = query.response as? [Stop] else {
                fatalError( ".theseStops returned something unexpected." )
            }
            
            var marks = [Mark]()
            var coords = [CLLocationCoordinate2D]()

            // Create the marks for the map and the coordinates
            for stop in stops {
                // Ignore child stations.
                if stop.parentID == nil {
                    marks.append( Mark(stop: stop) )
                    coords.append( stop.coordinate )
                }
            }
            
            if marks.isEmpty {
                return
            }
            
            // The usage data is a Bool.  If true, then set map region to display all of these stops.  True is the default.
            // The only time this is false is at startup when we load the users' favorite stops.
            let showMarks = query.uData as? Bool ?? true
            
            if !showMarks {
                //  Just add the marks to the map.
                Session.favorites = marks
                map.add( marks: marks )
                return
            }
            
            // GOAL: Create MKCoordinateRegion that includes all stops.

            // Get the extrema for the lat and lng
            let minLat = coords.min { $0.latitude < $1.latitude }!.latitude
            let maxLat = coords.max { $0.latitude < $1.latitude }!.latitude
            let minLon = coords.min { $0.longitude < $1.longitude }!.longitude
            let maxLon = coords.max { $0.longitude < $1.longitude }!.longitude

            let center = CLLocationCoordinate2D(latitude: minLat + (maxLat - minLat) / 2,
                                                longitude: minLon + (maxLon - minLon) / 2)
            
            let userLocation = map.getUserLocation() ?? center
            let closestMark = marks.closest(to: userLocation)
            
            map.display(marks: marks, kind: .stop, select: closestMark)
        
        case .routes:
            guard let routes = query.response as? [Route] else {
                fatalError("/routes returned something unexpected.")
            }
            
            guard let mark = query.uData as? Mark else {
                fatalError( "/routes didn't have a mark specified.")
            }
            
            map.set(subtitle: routes.makeList(), for: mark)
            

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
            
            guard let mark = query.uData as? Mark else {
                fatalError( "/predictions didn't have originating Mark. \(query)" )
            }
            
            guard let stop = mark.stop else {
                fatalError( "/predictions expected a stop. \(query)" )
            }
            
            
            if predictions.isEmpty {
                map.show(message: "No current predictions for \(stop.name)", timeout: 4.0)
                break
            }
                
            let sorted = predictions.sorted()
            map.show( predictions: sorted, for: mark )

            
        case .stopsOfRouteType:
            guard let stops = query.response as? [Stop] else {
                fatalError( "/stopsOfRoutType returned something unexpected. \(query)")
            }
            
            guard let filter = query.pData as? String else {
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

