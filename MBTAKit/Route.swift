//
//  Route.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/25/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import UIKit

public class Route: HasID {    
    
    public static let Unknown = Route()
    
    public struct Attributes: Decodable {
        let color: String
        let description: String
        let direction_names: [String]
        let long_name: String
        let short_name: String
        let sort_order: Int
        let text_color: String
        let type: Int
    }
    
    public let about: String
    public let type: GTFS.RouteType?
    public let shortName: String
    public let longName: String
    public let color: UIColor
    public let textColor: UIColor
    public let directions: [String]
    public let textAttrs: [ NSAttributedString.Key: UIColor ]
    public let sortOrder: Int
    
    // Full Name is a user readable string that completely declares the route.
    public var fullName: String {
        guard let type = type else {
            return "Unknown Route"
        }
        
        switch type {
        case .lightRail, .subway, .commuterRail:
            return( longName )
        case .bus, .ferry:
            // The shortName is empty for Silver Line buses between South Station and Silver Line Way
            if shortName.isEmpty {
                return longName
            }
            return( "\(shortName): \(longName)")
        }
    }
    
    public var mediumName: String {
        guard let type = type else {
            return "Unknown Route"
        }
        
        switch type {
        case .lightRail, .subway, .commuterRail:
            return( longName )
        case .bus, .ferry:
            // The shortName is empty for Silver Line buses between South Station and Silver Line Way
            if shortName.isEmpty {
                return longName
            }
            return( shortName )
        }
    }
    
    //  The shortest user readable string to identify this route.
    //  For bus, it is the id
    //  For heavyRail, it is the color, which currently is the ID.
    //  For lightRail, it is the shortName (B,C,D,E), except for Mattapan Trolley
    //  For Ferry, it is the first part of the long name
    //  For CR, it is the outer terminus, which currently is what follows the first "-"
    public var abbreviatedName: String {
        var plainName: String
        
        guard let type = type else {
            return "???"
        }
        
        switch type {
        case .bus, .lightRail:
            if id == "Mattapan" {
                plainName = "Mattapan"
                break
            }
            plainName = shortName
            
        case .subway:
            plainName = id
            
        case .commuterRail:
            if let dashIndex = id.firstIndex(of: "-") {
                let afterIndex = id.index(after: dashIndex)
                plainName = String(id[afterIndex...])
            } else {
                Debug.log( ".commuterRail ID not in expected form. \(self)")
                plainName = id
            }

        case .ferry:
            if let index = longName.firstIndex(of: " ") {
                plainName = String(longName[..<index])
            } else {
                Debug.log( ".ferry ID not in expected form. \(self)")
                plainName = longName
            }
        }
        
        return plainName
    }
    
    public func colorfy( string: String ) -> NSAttributedString {
        return( NSAttributedString(string: string, attributes: textAttrs)) 
    }
    
    private var _isUnknown = false
    public var isUnknown: Bool {
        return _isUnknown
    }
    
    private init() {
        about = "Unknown Route"
        shortName = "Route?"
        type = nil
        longName = "Unknown Route"
        color = UIColor.white
        textColor = UIColor.red
        directions = ["Unknown Source", "Unknown Sink"]
        _isUnknown = true
        textAttrs = [ NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.backgroundColor: color ]
        sortOrder = -1
        
        super.init(id: "route.unknown")
    }
    
    init( source: JXObject ) {
        guard let attributes = source.attributes as? Attributes else {
            fatalError( "Route could not get attributes from JXObject. \(source)")
        }
        
        self.about = attributes.description
        self.type = GTFS.RouteType( rawValue: attributes.type )
        self.color = UIColor( hex: attributes.color )
        self.textColor = UIColor( hex: attributes.text_color)
        self.shortName = attributes.short_name
        self.longName = attributes.long_name
        self.directions = attributes.direction_names
        self.textAttrs = [ NSAttributedString.Key.foregroundColor: textColor, NSAttributedString.Key.backgroundColor: color ]
        self.sortOrder = attributes.sort_order
        
        super.init( id: source.id)
    }
    
}

extension Array where Element == Route {
    
    public func makeList() -> NSAttributedString {
        
        let listOfRoutes = NSMutableAttributedString()
        for route in self {
            if listOfRoutes.length > 0 {
                listOfRoutes.append( NSAttributedString(string: " "))
            }
            listOfRoutes.append(route.colorfy(string: Strings.NBSP + route.abbreviatedName + Strings.NBSP))
        }
        
        return listOfRoutes
    }
}
