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
    
    var routeDict = [String: Route]()
    
    let map: MapManager!
    
    init( mapManager: MapManager ) {
        self.map = mapManager
        super.init()
        
        Query.listener = self
        ViciniT.share = self
   }
    
    override public var description: String {
        return( "ViciniT Core Object, v0.1")
    }
    
    func issue(_ query: Query ) {
        map.setDataPending( true )
        query.resume()
    }

    public func receive(query: Query) {
        process(query: query)
    }
    
    public func dataPendingUpdate(busy: Bool) {
        map.setDataPending(busy)
    }

    func showFavorites() {
        // GOAL:  Create a region that includes all favorites.
        let query = Query(kind: .theseStops, data: Array(UserSettings.shared.favoriteStops))
        issue( query )
    }
    
}

