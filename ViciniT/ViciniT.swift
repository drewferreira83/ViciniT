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
        if !UserSettings.shared.favoriteStops.isEmpty {
            _ = Query(kind: .theseStops, parameterData: Array( UserSettings.shared.favoriteStops), usageData: false)
        }
   }
    
    override public var description: String {
        return( "ViciniT Core Object, v0.1")
    }
    
    public func receive(query: Query) {
        process(query: query)
    }
    
    public func dataPendingUpdate(busy: Bool) {
        map.setDataPending(busy)
    }

    func showFavorites() {
        _ = Query(kind: .theseStops, parameterData: Array(UserSettings.shared.favoriteStops))
    }
    
}

