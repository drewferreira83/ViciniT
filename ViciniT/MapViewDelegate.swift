//
//  MapViewDelegate.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/24/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import MapKit

extension MapViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    // This is for custom annotations on the map, like stations and vehicles.  This refers to the
    // displayed symbol on the map, NOT THE CALLOUT BUBBLE.
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
     
        // Are we working with a custom annotation?
        if let mark = annotation as? Mark {
            if let markView = mapView.dequeueReusableAnnotationView(withIdentifier: MarkView.Identifier) as? MarkView {
                // We are reusing this annotation.  Need to overwrite the old values.
                markView.annotation = mark
                return markView
            } else {
                // Need to create a new custom annotation view
                return MarkView(mark: mark)
            }
        }
        
        return nil
    }
    
    //  This doesn't seem to be hit when the view is selected programmatically.
    //  If you do select it programmatically, call this function also.
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let markView = view as? MarkView {
            selectedMarkView = markView
            vicinit.didSelect( mark: markView.mark )
            
        }
    }
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // For the custom annotation views, send the callout away.
        if let markView = view as? MarkView {
            if selectedMarkView == markView {
                selectedMarkView = nil
            }
            
            vicinit.didDeselect( mark: markView.mark )
        }
    }

    
    //  Tapping on the simple bubble on an anno will trigger the detail to appear at the bottom of the screen.
    public func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let markView = view as? MarkView {
            vicinit.didSelectDetail( mark: markView.mark )
        }
    }
    
    // Need to turn off the callout for the User Location annotation view.
    // Can only change it here for some reason.
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        for view in views {
            // Disable the user annotation
            if view.annotation is MKUserLocation {
                view.canShowCallout = false
                view.isEnabled = false
            }
 
        }
    }

    private func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizer.State.began || recognizer.state == UIGestureRecognizer.State.ended ) {
                    userChangedRegion = true
                    return false
                    //return true
                }
            }
        }
        return false
    }
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        userInitiatedRegionChange = mapViewRegionDidChangeFromUserInteraction()

    }

    // The map's region has changed.  
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Update the stops, if appropriate.
        if userInitiatedRegionChange || forceShowStops {
            forceShowStops = false
            refreshStops()
        }

        updateMapElements()
    }
    
    // NB:  If the user changes location privs directly in Settings, this method is called when the app is made active again.
    // It is called before AppDelegate.applicatonDidBecomeActive.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // Show the user only if we are authorized.
        let showUser = (status == .authorizedWhenInUse || status == .authorizedAlways) && UserSettings.shared.trackUser
        
        DispatchQueue.main.async {
            self.mapView.showsUserLocation = showUser

            if let newCenter = Default.Location.manager.location?.coordinate {
                self.forceShowStops = true
                self.mapView.setCenter( newCenter, animated: true )
                self.updateMapElements()
            }
        }
    }

}



extension ViciniT {
    func didDeselect( mark: Mark ) {
        Debug.log( "didDeselect mark=\(mark)")
    }
    
    func didSelectDetail( mark: Mark ) {
        switch mark.kind {
        case .stop:
            guard let stop = mark.stop else {
                fatalError( "No Stop data for Mark \(mark)" )
            }
            
            // Get predictions
            _ =  Query(kind: .predictions, parameterData: stop )
            
        default:
            Debug.log( "Selected detail of \(mark), but ignored" )
        }
    }
    
    
    func didSelect( mark: Mark ) {
        
        switch mark.kind {
        case .stop:
            guard let stop = mark.stop else {
                fatalError( "No Stop data for Mark \(mark)")
            }

            // Get Routes at this stop.
            _ = Query( kind: .routes, parameterData: stop )

        default:
            Debug.log( "Selected \(mark), but ignored" )
        }
        
    }

}
