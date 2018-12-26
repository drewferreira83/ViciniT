//
//  MapViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/15/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit
import MapKit

// Only use these methods to interact with the MKMapView.
protocol MapManager {
    //    func set( region: MKCoordinateRegion )
    //    func set( center: CLLocationCoordinate2D )
    //    func removeMarks(ofKind: Mark.Kind)
    //    func getMarks(ofKind: Mark.Kind) -> [Mark]

    func ensureVisible( marks: [Mark])
    func display( marks: [Mark], kind: Mark.Kind, select: Mark?)
    func show( predictions: [Prediction], for stop: Stop )
    func show( routes: [Route], for stop: Stop )
    func setDataPending( _ state: Bool )
//    func select( mark: Mark )
    
    func getUserLocation() -> CLLocationCoordinate2D?
}

class MapViewController: UIViewController, MapManager {
    
    static public var shared: MapViewController!
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonBox: UIView!
    @IBOutlet weak var bannerBox: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var busyIndicator: UIActivityIndicatorView!
    
    @IBAction func dismissBannerBox(_ sender: Any) {
        bannerBox.fadeOut()
    }
    
    @IBAction func showFavorites(_ sender: Any) {
        vicinit.showFavorites()
    }
    
    // Recenter the map on the user's location.
    @IBAction func showLocation(_ sender: Any) {
        // We do want a search after the recenter.
        if let newCenter = Default.Location.manager.location?.coordinate {
            forceShowStops = true
            mapView.setCenter(newCenter, animated: true)
        }
    }
    
    var vicinit: ViciniT!
    
    var selectedMarkView: MarkView?
    var predictionsViewController: PredictionViewController!
    var predictionsNavVC: UINavigationController!
    
    var userInitiatedRegionChange = false
    var forceShowStops = false
    var refreshStopsOnReturn = false
    var markViewSize = MarkView.Size.medium
    
    override func viewDidLoad() {
        MapViewController.shared = self
        
        super.viewDidLoad()
        
        // Not 100% sure what register does, it is new with iOS 11...
        mapView.register(MarkView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        

        // Start functionality.
        Query.routeTypes = UserSettings.shared.routeTypes
        vicinit = ViciniT( mapManager: self )
        mapView.delegate = self
        locationButton.isHidden = true
        
        bannerBox.alpha = 0.0
        bannerLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 60 // Padding and cancel button
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        predictionsNavVC = mainStoryboard.instantiateViewController(withIdentifier: "PredictionsNavVC") as? UINavigationController
        predictionsViewController = predictionsNavVC.viewControllers[0] as? PredictionViewController
    
        Default.Location.manager.delegate = self
        Default.Location.manager.desiredAccuracy = kCLLocationAccuracyBest
        Default.Location.manager.distanceFilter = 50.0
        
        // If app authorization has not been determined, ask for permission from OS
        // Once set, it will remain set until app is deleted.
        
        var startRegion = Default.Map.region
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            Default.Location.manager.requestWhenInUseAuthorization()
            forceShowStops = true

        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if let here = Default.Location.manager.location?.coordinate {
                // We have the user's location, so overrride teh default start region.
                startRegion = MKCoordinateRegion(center: here, span: Default.Map.span)
            }
            
        default:
            mapView.showsUserLocation = false
            forceShowStops = true
        }
        
        mapView.setRegion( startRegion, animated: false )
    }
    
     override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /****  PUBLIC FUNCTIONS  ****/
    
    func getUserLocation() -> CLLocationCoordinate2D? {
        return Default.Location.manager.location?.coordinate
    }

    // Returns the actual MKAnnotation used in the MapView that matches the passed Mark object.
    private func annotationForMark( mark: Mark ) -> MKAnnotation? {
        for annotation in mapView.annotations {
            if let actualAnnotation = annotation as? Mark {
                if actualAnnotation == mark {
                    return actualAnnotation
                }
            }
        }
        
        return nil
    }
    
    
    // MAP REGION DOES NOT CHANGE:
    //This method will instruct the mapView to display the passed marks.
    // It will only add new Marks and it will remove any marks of the specified kind
    // that are not in the passed array.
    func display( marks: [Mark], kind: Mark.Kind, select: Mark? = nil ) {

        switch marks.count {
        case 0...8:
            markViewSize = .large
        case 9...40:
            markViewSize = .medium
        default:
            markViewSize = .small
        }
        
        
        // Which marks do we need to add to the existing annotations?
        var newMarks = [Mark]()
        for mark in marks {
            // This block looks in the current annotations and if it isn't already there, then it will be added.
            if (!mapView.annotations.contains {
                element in
                if let existingMark = element as? Mark {
                    return mark == existingMark
                } else {
                    return false
                }}) {
                newMarks.append( mark )
            }
        }
        
        // Which marks should be removed?  Only remove those of the specified kind.
        var removeMarks = [Mark]()
        for annotation in mapView.annotations {
            if let existingMark = annotation as? Mark {
                // Does this Mark match the kind AND is not in the passed array of marks?
                if existingMark.kind == kind &&
                    (!marks.contains {
                        mark in
                        return mark == existingMark }) {
                    // Slate this mark to be removed.
                    removeMarks.append( existingMark )
                }
            }
        }
        
        DispatchQueue.main.async {
            // Remove the annotations that are off-map.
            self.mapView.removeAnnotations(removeMarks)
            
            // Update the annotations that are still on the map.
            for annotation in self.mapView.annotations {
                if let markView = self.mapView.view(for: annotation) as? MarkView {
                    markView.size = self.markViewSize
                }
            }
            
            // Add the new annotations
            self.mapView.addAnnotations(newMarks)

            print( "Anno count = \(self.mapView.annotations.count)")
            
            if let markToSelect = select {
                self.mapView.showAnnotations(newMarks, animated: true)
                //self.mapView.setCenter( markToSelect.coordinate, animated: true )
                
                if let annotation = self.annotationForMark(mark: markToSelect) {
                    self.mapView.selectAnnotation(annotation, animated: true)
                } else {
                    Debug.log( "Could not find actual annotation in mapView for \(markToSelect).", flag: .error )
                }
            }
        }
    }

    // This displays the modal predictions view.
    func show(predictions: [Prediction], for stop: Stop) {
        DispatchQueue.main.async {
            self.predictionsViewController?.setPredictions( predictions, for: stop )
            if self.predictionsNavVC.presentingViewController == nil {
                self.present(self.predictionsNavVC, animated: true, completion: nil)
            } 
        }
    }
    
    // This updates the callout on the currently selected markView with the routes for that stop.
    func show( routes: [Route], for stop: Stop ) {
        guard let markView = selectedMarkView else {
            Debug.log( "Got routes for stop \(stop), but no marks are selected.", flag: .error)
            return
        }

        guard markView.mark?.stop == stop else {
            Debug.log( "Got routes for stop \(stop), but that mark isn't currently selected.", flag: .error )
            return
        }
        
        let listOfRoutes = routes.makeList()

        DispatchQueue.main.async {
            markView.routeLabel.attributedText = listOfRoutes
            markView.detailCalloutAccessoryView = markView.routeLabel
        }
    }
   
    // Move the map regiom so that these marks are visible
    func ensureVisible(marks: [Mark]) {
        mapView.showAnnotations(marks, animated: true)
    }
    
    // TODO:  Implement UI to change settings.
    func set( mapOptions: UserSettings.MapOptions ) {
        // Not changable.
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.showsCompass = false

        // Changable settings
        mapView.mapType = mapOptions.mapType
        mapView.showsPointsOfInterest = mapOptions.showsPointsOfInterest
        mapView.showsBuildings = mapOptions.showsBuildings
        mapView.showsScale = mapOptions.showsScale
        mapView.showsTraffic = mapOptions.showsTraffic
    }
    
    // The selectedMarkView might need to be redrawn if its favorite status changed.
    //  The showFavoritesButton is shown if there are favorites.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedMarkView?.prepareForDisplay()
        
        // Should the stops be refreshed?
        if refreshStopsOnReturn {
            refreshStopsOnReturn = false
            refreshStops()
        }
        
        updateButtonBox()
    }
    
    // Called from AppDelegate when App comes back to foreground
    func didBecomeActive() {
        predictionsViewController.reloadPressed( self ) // NOOP if predictions isn't up
        updateButtonBox()
    }
    
    func updateButtonBox() {
        favoriteButton.isHidden = UserSettings.shared.favoriteStops.isEmpty

        // Validate user tracking. The user may have changed settings within the map or directly through Device Settings.
        mapView.showsUserLocation = UserSettings.shared.trackUser && Default.Location.accessible

        // Hide the location button if any is true:
        //   MapView isn't showing user location (validation above checks both app flag and device privs)
        //   The user location is currently visible

        locationButton.isHidden =  !mapView.showsUserLocation || mapView.isUserLocationVisible
        
        buttonBox.isHidden = (locationButton.isHidden && favoriteButton.isHidden)
    }
  
    func refreshStops() {
        let excludeBuses = mapView.region.span.maxDelta > 0.04
        
        if excludeBuses && UserSettings.shared.routeTypes[GTFS.RouteType.bus.rawValue] && !Session.zoomInForBuses {
            bannerLabel.text = "Zoom in to see bus stops"
            bannerBox.fadeIn()
            Session.zoomInForBuses = true
        } else {
            bannerBox.fadeOut()
        }
        
        let kind: Query.Kind = excludeBuses ? .majorStopsInRegion : .allStopsInRegion
        let query = Query(kind: kind, data: mapView.region)
    
        query.resume()
    }
    
    func setDataPending( _ state: Bool ) {
        DispatchQueue.main.async {
            if state {
                self.busyIndicator.startAnimating()
            } else {
                self.busyIndicator.stopAnimating()
            }
        }
    }
    

}


