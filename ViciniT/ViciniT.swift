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
    var lastLocation: CLLocationCoordinate2D?
    
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
    
    public func receive(query: Query) {
        process(query: query)
    }
    
    func showFavorites() {
        // GOAL:  Create a region that includes all favorites.
        let query = Query(kind: .favoriteStops, data: Array(UserSettings.shared.favoriteStops))
        query.resume()
    }
}

