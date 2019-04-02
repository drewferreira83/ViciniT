//
//  GTFS.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 12/31/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

public struct GTFS {
    // These are the keys to the GTFS data structures
    public enum Kind: String {
        case route, stop, trip, vehicle, prediction, schedule, parent_station
        // service, shape, child_stops
    }
    
    public enum RelationshipKey: String {
        case parent_station
        case child_stops
    }
    
    public enum LocationType: Int {
        case unknown = -1  // Extension
        case stop = 0
        case station = 1
        case entrance = 2
    }
    
    // Wheelchair boarding in GTFS
    public enum Accessibility: Int {
        case unknown = 0
        case accessible = 1
        case notAccessible = 2
    }
    
    // Valid values in GTFS
    public enum VehicleStatus: String {
        case incoming = "INCOMING_AT"      // Approaching station
        case stopped = "STOPPED_AT"        // At station
        case inTransit = "IN_TRANSIT_TO"   // Departed previous station
        
        case unknown = "unknown"
    }
    
    // What to display for the previous statuses.
    public static let VehicleStatusDescription: [VehicleStatus: String] = [
        VehicleStatus.incoming: "Entering",
        VehicleStatus.stopped: "Stopped at",
        VehicleStatus.inTransit: "In transit to",
        VehicleStatus.unknown: "Unknown status"]
    
    //  https://github.com/google/transit/blob/master/gtfs/spec/en/reference.md#stop_timestxt
    public enum ScheduledStopType: Int {
        case regular = 0
        case none = 1
        case contactAgency = 2
        case contactDriver = 3
    }
    
    // To the user, SUBWAY = (lightRail + subway).  No distinction between the two.
    public enum RouteType: Int, CaseIterable {
        case lightRail
        case subway
        case commuterRail
        case bus
        case ferry
    }
}

public struct MBTA {
    public enum RouteType: Int, CaseIterable {
        case subway, commuterRail, bus, ferry
    }
    
    public static func codeFor( routeType: RouteType) -> String {
        switch routeType {
        case .subway:
            return "0,1"
        case .commuterRail:
            return "2"
        case .bus:
            return "3"
        case .ferry:
            return "4"
        }
    }

    public static func routeType( gtfsType: GTFS.RouteType) -> RouteType {
        switch (gtfsType) {
        case .subway, .lightRail:
            return RouteType.subway
        case .commuterRail:
            return RouteType.commuterRail
        case .bus:
            return RouteType.bus
        case .ferry:
            return RouteType.ferry
        }
    }
}
