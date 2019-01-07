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
    func center( mark: Mark )
    
    func show( message: String?, timeout: TimeInterval? )
    func show( predictions: [Prediction], for mark: Mark )
    func set( subtitle: NSAttributedString, for mark: Mark )
    func set( dataPending: Bool )
    
    func getUserLocation() -> CLLocationCoordinate2D?
    func getMapRect() -> MKMapRect
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
    
    @IBOutlet weak var buttonStack: UIStackView!
    @IBOutlet weak var searchBox: UIView!
 
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
            forceRefreshOnRegionChange = true
            mapView.setCenter(newCenter, animated: true)
        }
    }
    
    var vicinit: ViciniT!
    
    var selectedMarkView: MarkView?
    var predictionsViewController: PredictionViewController!
    var predictionsNavVC: UINavigationController!
    
    var forceRefreshOnRegionChange = false
    var forceRefreshOnAppear = false
    var zoomMessageDismissed = false
    var userChangedRegion = false
    
    override func viewDidLoad() {
        MapViewController.shared = self
        vicinit = ViciniT( mapManager: self )

        // Not 100% sure what register does, it is new with iOS 11...
        mapView.register(MarkView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        // Map Attributes that aren't changabled.
        mapView.showsPointsOfInterest = false
        mapView.mapType = .mutedStandard
        mapView.showsScale = true

        // Get User settings...
        Query.validModes = UserSettings.shared.validModes
        mapView.delegate = self

        // Init UI elements
        //buttonBox.alpha = 0.0
        bannerBox.alpha = 0.0
        bannerLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 60 // Padding and cancel button\
        
        // Create the Predictions View Controller.
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        predictionsNavVC = mainStoryboard.instantiateViewController(withIdentifier: "PredictionsNavVC") as? UINavigationController
        predictionsViewController = predictionsNavVC.viewControllers[0] as? PredictionViewController
    
        //  Check on location services and permission.
        Default.Location.manager.delegate = self
        Default.Location.manager.desiredAccuracy = kCLLocationAccuracyBest
        Default.Location.manager.distanceFilter = 50.0
        
        // If app authorization has not been determined, ask for permission from OS
        // Once set, it will remain set until app is deleted.
        
        var startRegion = Default.Map.region
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            Default.Location.manager.requestWhenInUseAuthorization()
            forceRefreshOnRegionChange = true

        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if let here = Default.Location.manager.location?.coordinate {
                // We have the user's location, so overrride teh default start region.
                startRegion = MKCoordinateRegion(center: here, span: Default.Map.span)
            }
            
        default:
            mapView.showsUserLocation = false
            forceRefreshOnRegionChange = true
        }
        
        mapView.setRegion( startRegion, animated: true )
        
        super.viewDidLoad()
    }
    
     override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /****  PUBLIC FUNCTIONS  ****/
    
    func getMapRect() -> MKMapRect {
        return mapView.visibleMapRect
    }

    func getUserLocation() -> CLLocationCoordinate2D? {
        guard mapView.showsUserLocation else {
            return nil
        }
        
        return Default.Location.manager.location?.coordinate
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
    
    func center( mark: Mark ) {
        forceRefreshOnRegionChange = true
        mapView.setCenter(mark.coordinate, animated: true)
    }
    
    // MAP REGION DOES NOT CHANGE:
    //This method will instruct the mapView to display the passed marks.
    // It will only add new Marks and it will remove any marks of the specified kind
    // that are not in the passed array.
    func display( marks: [Mark], kind: Mark.Kind, select: Mark? = nil ) {
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
    func show(predictions: [Prediction], for mark: Mark) {
        DispatchQueue.main.async {
            self.predictionsViewController?.setPredictions( predictions, for: mark )
            if self.predictionsNavVC.presentingViewController == nil {
                self.present(self.predictionsNavVC, animated: true, completion: nil)
            } 
        }
    }
    
    // This updates the callout on the currently selected markView with the routes for that stop.
    func set( subtitle: NSAttributedString, for mark: Mark ) {
        guard let markView = selectedMarkView else {
            Debug.log( "Got routes for mark\(mark), but no marks are selected.", flag: .error)
            return
        }

        guard markView.mark == mark else {
            Debug.log( "Got routes for mark \(mark), but that mark isn't currently selected.", flag: .error )
            return
        }
        

        DispatchQueue.main.async {
            markView.detailLabel.attributedText = subtitle
            markView.detailCalloutAccessoryView = markView.detailLabel
        }
    }
   
    // Move the map regiom so that these marks are visible
    func ensureVisible(marks: [Mark]) {
        forceRefreshOnRegionChange = true
        mapView.showAnnotations(marks, animated: true)
    }

    // The selectedMarkView might need to be redrawn if its favorite status changed.
    //  The showFavoritesButton is shown if there are favorites.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        selectedMarkView?.prepareForDisplay()
        
        // Should the stops be refreshed?
        if forceRefreshOnAppear {
            forceRefreshOnAppear = false
            refreshStops()
        }
        
        updateUI()
    }
    
    // Called from AppDelegate when App comes back to foreground
    func didBecomeActive() {
        predictionsViewController.reloadPressed( self ) // NOOP if predictions isn't up
        updateUI()
    }
    
    var searchLabelTimer: Timer?
    
    func updateUI() {
        mapView.showsTraffic = UserSettings.shared.showsTraffic

        // Validate user tracking. The user may have changed in-app settings or directly through Device Settings.
        mapView.showsUserLocation = UserSettings.shared.trackUser && Default.Location.accessible

        // BUTTON BOX
        
        // Hide the location button if any is true:
        //   MapView isn't showing user location (validation above checks both app flag and device privs)
        //   The user location is currently visible
        let hideLocationButton = !mapView.showsUserLocation || mapView.isUserLocationVisible
        let hideFavoriteButton = UserSettings.shared.favoriteIDs.isEmpty
        let hideButtonBox = hideLocationButton && hideFavoriteButton

        
        UIView.animate(withDuration: Default.aniDuration) {() -> Void in
            self.buttonBox.alpha = hideButtonBox ? 0.0 : 1.0
            self.locationButton.isHidden = hideLocationButton
            self.favoriteButton.isHidden = hideFavoriteButton
        }

        // Note regarding animation of the buttons and its container:
        //   The buttons are inside a stackview which takes care of sizing itself when child objects are added/removed/hidden.
        //   This is why the buttons are toggled by changing the .isHidden component.
        //   The buttonBox is a generic UIView.  If the buttonBox is hidden, the stackview will not resize based on changes in
        //   its children.  This is why to hide the buttonBox, we change its .alpha component.
        
        
        // SEARCH BOX
        // Display the search box if the user has changed the region and the auto-seach isn't on.
        if userChangedRegion && !UserSettings.shared.searchOnScroll {
            // If the search box is invisible, then fade it in.
            if searchBox.alpha == 0.0 {
                searchLabelButton.isHidden = false
                searchBox.fadeIn()
            
                // If there is no current timer, then make one that will hide the help message in a few seconds.
                if searchLabelTimer == nil {
                    searchLabelTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ -> Void in
                        UIView.animate(withDuration: Default.aniDuration) { () -> Void in
                            self.searchLabelButton.isHidden = true
                        }
                        
                        self.searchLabelTimer = nil
                    }
                }
            }
        } 
    }
    
    var bannerTimer: Timer?
    
    // Show the message and have it fade out if a timeout is given
    // nil hides message immediately.
    func show(message: String?, timeout: TimeInterval? = nil) {
        if bannerTimer != nil && bannerTimer!.isValid {
            bannerTimer!.invalidate()
            bannerTimer = nil
        }
        
        DispatchQueue.main.async {
            // Nil message means dismiss.
            guard let message = message else {
                self.bannerBox.fadeOut()
                return
            }
            
            self.bannerLabel.text = message
            self.bannerBox.fadeIn()

            // Set up a timer if we want this to dismiss itself.
            if let timeout = timeout {
                self.bannerTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false ) { _ in
                    self.bannerBox.fadeOut()
                    self.bannerTimer = nil
                }
            }
        }
    }
  
    func refreshStops() {
        vicinit.searchForStops(in: mapView.region)
        searchBox.fadeOut()
    }
    
    func set( dataPending: Bool ) {
        DispatchQueue.main.async {
            dataPending ? self.busyIndicator.startAnimating() : self.busyIndicator.stopAnimating()
        }
    }
}
