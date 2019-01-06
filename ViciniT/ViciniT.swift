//
//  Core.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/21/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

public class ViciniT: NSObject, QueryListener {
    static public var share: ViciniT!
    
    let map: MapManager!
    
    init( mapManager: MapManager ) {
        self.map = mapManager
        super.init()
        
        Query.listener = self
        ViciniT.share = self
        
        // Ask for list of subway stops and commuter rail stops.
        _ = Query(kind: .stopsOfRouteType, parameterData: MBTA.stopType.subway)
        _ = Query(kind: .stopsOfRouteType, parameterData: MBTA.stopType.commRail)
        _ = Query(kind: .stopsOfRouteType, parameterData: MBTA.stopType.ferry)
        
        // Ask for favorite stops, if any.
        if !UserSettings.shared.favoriteIDs.isEmpty {
            _ = Query(kind: .theseStops, parameterData: Array( UserSettings.shared.favoriteIDs), usageData: false)
        }
   }
    
    override public var description: String {
        return( "ViciniT Core Object, v0.1")
    }
    
    public func receive(query: Query) {
        process(query: query)
    }
    
    public func dataPendingUpdate(busy: Bool) {
        map.set(dataPending: busy)
    }

    private func showAllFavorites() {
        if Session.favorites.isEmpty {
            return
        }

        map.ensureVisible(marks: Array(Session.favorites))
    }
    
    public func showFavorites() {
        // User pressed show favs button.
        // SHOW ALL FAVORITES IF
        //     No access to User location
        //     Closest Favorite stop is on screen
        // SCROLL TO CLOSEST FAVORITE otherwise
        
        guard !Session.favorites.isEmpty else {
            fatalError( "No Favorites to display?" )
        }
        
        guard let userLocation = map.getUserLocation() else {
            showAllFavorites()
            return
        }
        
        // Which favorite mark is closest?
        let closest = Session.favorites.closest(to: userLocation)
        let visibleMapRect = map.getMapRect()
        
        //  If the closest mark is already on the map, then show All Favorites
        if visibleMapRect.contains(closest.mapPoint) {
            showAllFavorites()
            return
        }
        
        // Center the map on the closest mark.
        map.center( mark: closest )
    }
    
    public func searchForStops( in region: MKCoordinateRegion ) {
        let excludeBuses = region.span.maxDelta > 0.04
        
        if excludeBuses && UserSettings.shared.validModes[GTFS.RouteType.bus.rawValue]  {
            map.show(message: "Zoom in to see bus stops", timeout: 8.0)
        } 
        
        let kind: Query.Kind = excludeBuses ? .majorStopsInRegion : .allStopsInRegion
        _ = Query(kind: kind, parameterData: region)
    }
}

