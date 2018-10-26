//
//  CustomAnnotationView.swift
//  GoBOS
//
//  Created by Andrew Ferreira on 5/5/16.
//  Copyright © 2016 Andrew Ferreira. All rights reserved.
//

import UIKit
import MapKit

// These objects may be reused by the mapViewController.  When the underlying customAnnotation is updated, the image of the 
// view will be updated to correct type and rotation (if applicable)
class MarkView: MKAnnotationView {
    enum ClusterType: String {
        case station, stop
    }
    
    static let Identifier = "MarkView"
    let routeLabel = UILabel()
    
    var mark: Mark? {
        return annotation as? Mark
    }
    
    init( mark: Mark ) {
        super.init(annotation: mark, reuseIdentifier: MarkView.Identifier)
        
        isOpaque = false
        canShowCallout = true

        // Create the route label.  It is not immediately displayed.
        routeLabel.font = Default.Font.forCalloutSubtitle
        routeLabel.numberOfLines = 0
        routeLabel.lineBreakMode = .byWordWrapping
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("MarkView.init(coder:) has not been implemented")
    }
    
    override public var description: String {
        return( "[MarkView: isEnabled=\(isEnabled);isDraggable:\(isDraggable);super:\(super.description)]" )
    }
    
    override func prepareForDisplay() {
        super.prepareForDisplay()
        
        // Probably won't happen, and it's not a bad thing if it does.  Just ignore it.
        guard let mark = mark else {
            Debug.log( "Annotation not a Mark: \(String(describing: annotation))")
            return
        }
        
        var newImage : UIImage!

        switch (mark.kind) {
        case .stop where mark.isFavorite:
            newImage = Default.Images.favoriteStop

        case .stop:
            // GTFS.locationType .stations means that it is a physical structure or it has children stops.
            let stopType = mark.stop!.locationType

            switch mark.scopeLevel {
            case .normal:
                newImage = stopType == .station ? Default.Images.stop24 : Default.Images.stop18
                
            case .medium:
                newImage = stopType == .station ? Default.Images.stop18 : Default.Images.stop12
                
            case .high:
                newImage =  Default.Images.stop12
                
            default:
                fatalError( "Unsupported Scope.Level for \(mark)" )
            }
            
        case .vehicle:
            newImage = mark.scopeLevel == .normal ? Default.Images.vehicle24 : Default.Images.vehicle12
            newImage = newImage.rotate( byDegrees: mark.rotation)
            
        default:
            Debug.log("Unexpected mark type. \(self)")
            break
        }
        self.image = newImage
    }
    
    open func dismiss() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }

    override func prepareForReuse() {
        detailCalloutAccessoryView = nil
    }
 
}
