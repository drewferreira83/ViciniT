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
    
    enum Size {
        case small, medium, large
    }
    
    enum ClusterType: String {
        case station, stop
    }
    
    static let Identifier = "MarkView"
    let detailLabel = UILabel()
    
    var _size = Size.medium
    var size: Size {
        set (value) {
            if value != _size {
                setNeedsDisplay()
            }
            _size = value
        }
        
        get {
            return _size
        }
    }
    
    var mark: Mark? {
        return annotation as? Mark
    }
    
    init( mark: Mark ) {
        super.init(annotation: mark, reuseIdentifier: MarkView.Identifier)
        
        isOpaque = false
        canShowCallout = true

        // Create the route label.  It is not immediately displayed.
        detailLabel.font = Default.Font.forCalloutSubtitle
        detailLabel.numberOfLines = 0
        detailLabel.lineBreakMode = .byWordWrapping
        rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("MarkView.init(coder:) has not been implemented")
    }
    
    override public var description: String {
        return( "[MarkView: isEnabled=\(isEnabled);isDraggable:\(isDraggable);super:\(super.description)]" )
    }
    
    override func prepareForDisplay() {
        
        // Probably won't happen, and it's not a bad thing if it does.  Just ignore it.
        guard let mark = mark else {
            Debug.log( "Annotation not a Mark: \(String(describing: annotation))")
            return
        }
        
        var newImage : UIImage!

        switch (mark.kind) {
        case .stop where mark.isFavorite:
            // Favorite Stops...
            newImage = Images.favoriteStop20

        case .stop:
            if Session.subwayStopIDs.contains(mark.stop!.id) {
                newImage = Images.stop12
            } else if Session.commRailIDs.contains(mark.stop!.id) {
                newImage = Images.stopRail12
            } else {
                newImage = Images.stop08
            }

            
        case .vehicle:
            // Vehicles
            newImage = Images.vehicle12
            newImage = newImage.rotate( byDegrees: mark.rotation)
        }
        
        self.image = newImage
        
        super.prepareForDisplay()
    }
    
    open func dismiss() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }

    override func prepareForReuse() {
        detailCalloutAccessoryView = nil
    }
 
    deinit {
        detailCalloutAccessoryView = nil
        image = nil
    }
    
}

