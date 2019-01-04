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
    func add( marks: [Mark])
    func remove( marks: [Mark])
    
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
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchLabelButton: UIButton!
    
    @IBOutlet weak var searchBox: UIView!
    
    var userChangedRegion: Bool {
        get { return _userChangedRegion }
        set (value) {
            _userChangedRegion = value
            updateMapElements()
        }
    }
    
    @IBAction func dismissBannerBox(_ sender: Any) {
        zoomMessageDismissed = true
        bannerBox.fadeOut()
    }
    
    @IBAction func searchForStops(_ sender: Any) {
        refreshStops()
        
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
    var zoomMessageDismissed = false
    var _userChangedRegion = false
    //var markViewSize = MarkView.Size.medium
    
    override func viewDidLoad() {
        MapViewController.shared = self
        
        super.viewDidLoad()
        
        // Not 100% sure what register does, it is new with iOS 11...
        mapView.register(MarkView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        mapView.mapType = .mutedStandard
        mapView.showsScale = true
        mapView.showsTraffic = UserSettings.shared.showsTraffic

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
    
    
    func add(marks: [Mark]) {
        // Add these marks - don't do anything else.
        DispatchQueue.main.async {
            self.mapView.addAnnotations(marks)
        }
    }
    
    func remove(marks: [Mark]) {
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(marks)
        }
    }
    
    func select(mark: Mark) {
    }
    
    // MAP REGION DOES NOT CHANGE:
    //This method will instruct the mapView to display the passed marks.
    // It will only add new Marks and it will remove any marks of the specified kind
    // that are not in the passed array.
    func display( marks: [Mark], kind: Mark.Kind, select: Mark? = nil ) {
/*
        switch marks.count {
        case 0...8:
            markViewSize = .large
        case 9...40:
            markViewSize = .medium
        default:
            markViewSize = .small
        }
*/
        
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
        var invalidMarks = [Mark]()
        for annotation in mapView.annotations {
            if let existingMark = annotation as? Mark {
                // Does this Mark match the kind AND ins't a favorite AND is not in the passed array of marks?
                if existingMark.kind == kind &&
                    !existingMark.isFavorite &&
                    (!marks.contains {
                        mark in
                        return mark == existingMark }) {
                    // Slate this mark to be removed.
                    invalidMarks.append( existingMark )
                }
            }
        }
        
        remove( marks: invalidMarks )
        add( marks: newMarks )
        
        // If we're given a mark to select...
        if let markToSelect = select {
            DispatchQueue.main.async {
                self.mapView.showAnnotations(newMarks, animated: true)
                self.mapView.selectAnnotation(markToSelect, animated: true)
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
            markView.detailLabel.attributedText = listOfRoutes
            markView.detailCalloutAccessoryView = markView.detailLabel
        }
    }
   
    // Move the map regiom so that these marks are visible
    func ensureVisible(marks: [Mark]) {
        mapView.showAnnotations(marks, animated: true)
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
        
        updateMapElements()
    }
    
    // Called from AppDelegate when App comes back to foreground
    func didBecomeActive() {
        predictionsViewController.reloadPressed( self ) // NOOP if predictions isn't up
        updateMapElements()
    }
    
    var searchLabelTimer: Timer?
    
    func updateMapElements() {
        mapView.showsTraffic = UserSettings.shared.showsTraffic

        // Validate user tracking. The user may have changed in-app settings or directly through Device Settings.
        mapView.showsUserLocation = UserSettings.shared.trackUser && Default.Location.accessible

        // BUTTON BOX
        
        // Hide the location button if any is true:
        //   MapView isn't showing user location (validation above checks both app flag and device privs)
        //   The user location is currently visible
        let hideLocationButton = !mapView.showsUserLocation || mapView.isUserLocationVisible
        let hideFavoriteButton = UserSettings.shared.favoriteStops.isEmpty
        let hideButtonBox = hideLocationButton && hideFavoriteButton

        UIView.animate(withDuration: 0.5) {() -> Void in
            self.locationButton.isHidden = hideLocationButton
            self.favoriteButton.isHidden = hideFavoriteButton
            self.buttonBox.alpha = hideButtonBox ? 0.0 : 1.0
        }

        // Note regarding animation of the buttons and its container:
        //   The buttons are inside a stackview which takes care of sizing itself when child objects are added/removed/hidden.
        //   This is why the buttons are toggled by changing the .isHidden component.
        //   The buttonBox is a generic UIView.  If the buttonBox is hidden, the stackview will not resize based on changes in
        //   its children.  This is why to hide the buttonBox, we change its .alpha component.
        
        
        // SEARCH BOX
        
        if userChangedRegion {
            // If the search box is invisilble, then fade it in.
            if searchBox.alpha == 0.0 {
                searchLabelButton.isHidden = false
                searchBox.fadeIn()
            
                // If there is no current timer, then make one that will hide the help message in a few seconds.
                if searchLabelTimer == nil {
                    searchLabelTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ -> Void in
                        UIView.animate(withDuration: 0.25) { () -> Void in
                            self.searchLabelButton.isHidden = true
                        }
                        
                        self.searchLabelTimer = nil
                    }
                }
            }
        } else {
            searchBox.fadeOut()
        }

        
    }
  
    func refreshStops() {
        let excludeBuses = mapView.region.span.maxDelta > 0.04
        
        if excludeBuses && UserSettings.shared.routeTypes[GTFS.RouteType.bus.rawValue] && !zoomMessageDismissed {
            bannerLabel.text = "Zoom in to see bus stops"
            print( "Banner fade in." )
            bannerBox.fadeIn()
            _ = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: false ) { _ in
                print( "Banner fade out.")
                self.bannerBox.fadeOut()
            }
        } else {
            bannerBox.fadeOut()
        }
        
        let kind: Query.Kind = excludeBuses ? .majorStopsInRegion : .allStopsInRegion
        _ = Query(kind: kind, parameterData: mapView.region)
        userChangedRegion = false
    }
    
    func setDataPending( _ state: Bool ) {
        DispatchQueue.main.async {
            state ? self.busyIndicator.startAnimating() : self.busyIndicator.stopAnimating()
        }
    }
    

}


