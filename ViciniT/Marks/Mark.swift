//
//  CustomAnnotation.swift
//  TQuery
//
//  Created by Andrew Ferreira on 12/27/15.
//  Copyright © 2015 Andrew Ferreira. All rights reserved.
//

import UIKit
import MapKit


open class Mark: NSObject, MKAnnotation {
    enum Kind: String {
        case stop, vehicle
    }

    public let coordinate: CLLocationCoordinate2D
    public let mapPoint: MKMapPoint
    public let location: CLLocation
    public let title: String?
    public var subtitle: String?
    
    public let stop: Stop?
    public let vehicle: Vehicle?

    var kind: Kind
    var rotation: Int = 0
    
    
    public var id: String {
        switch kind {
        case .stop:
            return stop!.id
            
        case .vehicle:
            return vehicle!.id
        }
    }
    
    var isFavorite: Bool {
        get {
            guard let stopID = self.stop?.id else { return false }
            
            return UserSettings.shared.favoriteIDs.contains(stopID)
        }
        
        set (value) {
            guard let stopID = self.stop?.id else { return }
            
            if value {
                UserSettings.shared.favoriteIDs.insert( stopID )
                Session.favorites.append( self )
            } else {
                UserSettings.shared.favoriteIDs.remove( stopID )
                if let index = Session.favorites.firstIndex(of: self) {
                    Session.favorites.remove(at: index)
                }
            }
        }
    }

    init( stop: Stop ) {
        //  HACK:  To ensure minimum width of callout bubble, pad short stop names with spaces.
        self.coordinate = stop.coordinate
        self.location = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude )
        self.mapPoint = MKMapPoint(stop.coordinate)
        self.kind = .stop
        self.title = stop.name + (stop.name.count < 20  ? "            " : "")
        self.subtitle = nil 
        self.stop = stop
        self.vehicle = nil

        super.init()
    }

    init( vehicle: Vehicle) {
        self.kind = .vehicle
        self.stop = nil
        self.vehicle = vehicle
        self.coordinate = vehicle.coordinate
        self.location = CLLocation(latitude: vehicle.coordinate.latitude, longitude: vehicle.coordinate.longitude )
        self.mapPoint = MKMapPoint(vehicle.coordinate)
        self.rotation = vehicle.bearing ?? 0

        // IF there is additional information about the vehicle...
        //  Title = Route Short Name + Trip Direction
        // Subtitle = Status + Stop
        if let route = vehicle.route, let trip = vehicle.trip {
            self.title = route.mediumName + " " + vehicle.directionName + " to " + trip.headsign
            self.subtitle = vehicle.statusText
        } else {
            self.title = "No data available"
            
            self.subtitle = "Sorry"
        }

        super.init()
    }

 
    override open var description: String {
        return( "(Mark:\(kind) \"\(title ?? "No title")\" super[\(super.description)])")
    }
  
    public func distance( from mark: Mark ) -> CLLocationDistance {
        return location.distance(from: mark.location)
    }
    
    public func distance( from coordinate: CLLocationCoordinate2D ) -> CLLocationDistance {
        let there = CLLocation( latitude: coordinate.latitude, longitude: coordinate.longitude )
        return location.distance( from: there )
    }
    
}

// Two marks are the same if they are at the same scope, of the same kind, and they have the same coordinates.
func ==(lhs: Mark, rhs: Mark) -> Bool {
    return ((lhs.kind == rhs.kind) &&
           // (lhs.scopeLevel == rhs.scopeLevel) &&
            (lhs.coordinate.latitude == rhs.coordinate.latitude) &&
            (lhs.coordinate.longitude == rhs.coordinate.longitude))
}

extension Array where Element == Mark {
    public func closest( to coords: CLLocationCoordinate2D ) -> Mark {
        guard !self.isEmpty else {
            fatalError( "Set is empty! No such thing as closest")
        }
        
        var closestMark: Mark!
        var leastDistance: CLLocationDistance = .infinity
        
        for mark in self {
            let distance = mark.distance(from: coords)
            
            if distance < leastDistance {
                leastDistance = distance
                closestMark = mark
            }
        }
        
        return closestMark
    }
}


//ImageRotation.swift


extension UIImage {
    public func rotate(byDegrees: Int, flip: Bool = false) -> UIImage {
        /*  TODO:  Need to return a COPY
         if degrees == 0 {
         return( UIImage(ciImage: self.ciImage!))
         }
         */
        
        if byDegrees == 0 {
            return self
        }
        
        let rads = CGFloat(byDegrees) / 180.0 * CGFloat(Double.pi)
        
        // calculate the size of the rotated view's containing box for our drawing space
        let rotatedViewBox = UIView(frame: CGRect(origin: CGPoint.zero, size: size))
        let t = CGAffineTransform(rotationAngle: rads)
        rotatedViewBox.transform = t
        let rotatedSize = rotatedViewBox.frame.size
        
        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap = UIGraphicsGetCurrentContext()
        
        // Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap?.translateBy(x: rotatedSize.width / 2.0, y: rotatedSize.height / 2.0);
        
        //   // Rotate the image context
        bitmap?.rotate(by: rads)
        
        // Now, draw the rotated/scaled image into the context
        var yFlip: CGFloat
        
        if(flip){
            yFlip = CGFloat(-1.0)
        } else {
            yFlip = CGFloat(1.0)
        }
        
        bitmap?.scaleBy(x: yFlip, y: -1.0)
        bitmap?.draw(cgImage!, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}


