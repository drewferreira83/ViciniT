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
        case stop, vehicle, all
    }

    public let coordinate: CLLocationCoordinate2D
    public let location: CLLocation
    public let title: String?
    public var subtitle: String?
    public var scopeLevel: Scope.Level
    
    public let stop: Stop?
    public let vehicle: Vehicle?
    
    var isFavorite: Bool {
        get {
            return stop?.isFavorite ?? false
        }
    }
    var image: UIImage?
    var kind: Kind
    var rotation: Int = 0

    init( stop: Stop, scopeLevel: Scope.Level = Scope.Level.normal) {
        //  HACK:  To ensure minimum width of callout bubble, pad short stop names with spaces.
        self.coordinate = stop.coordinate
        self.location = CLLocation(latitude: stop.coordinate.latitude, longitude: stop.coordinate.longitude )
        self.kind = .stop
        self.title = stop.name + (stop.name.count < 20  ? "            " : "")
        self.subtitle = nil 
        self.stop = stop
        self.vehicle = nil
        self.scopeLevel = scopeLevel

        super.init()
    }

    init( vehicle: Vehicle, scopeLevel: Scope.Level = .normal ) {
        self.coordinate = vehicle.coordinate
        self.location = CLLocation(latitude: vehicle.coordinate.latitude, longitude: vehicle.coordinate.longitude )
        self.kind = .vehicle
        self.title = vehicle.id
        self.subtitle = vehicle.status.rawValue
        self.vehicle = vehicle
        self.rotation = vehicle.bearing ?? 0
        self.stop = nil
        self.scopeLevel = scopeLevel

        super.init()
    }
    
    deinit {
        // Should Stop and Vehicle also be set to nil?
        image = nil
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
            (lhs.scopeLevel == rhs.scopeLevel) &&
            (lhs.coordinate.latitude == rhs.coordinate.latitude) &&
            (lhs.coordinate.longitude == rhs.coordinate.longitude))
}

extension Array where Element == Mark {
    public func closest( to coords: CLLocationCoordinate2D ) -> Mark? {
        var closestMark: Mark?
        
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

