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

    func display( marks: [Mark], kind: Mark.Kind, setRegion: Bool )
    func add( marks: [Mark])
    func remove( marks: [Mark])
    func center( mark: Mark )
    
    func suspendAutoSearch( message: String )
    
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
        searchOnRegionChange = true
        searchBox.fadeOut()
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
    var searchOnRegionChange = true
    
    override func viewDidLoad() {
        MapViewController.shared = self
        vicinit = ViciniT( mapManager: self )

        // Not 100% sure what register does, it is new with iOS 11...
        mapView.register(MarkView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        // Map Attributes that aren't changabled.
        mapView.showsPointsOfInterest = false  // Appears to be not functional.
        mapView.mapType = .mutedStandard
        mapView.showsScale = true

        // Get User settings...
        Query.validModes = UserSettings.shared.validModes
        mapView.delegate = self

        // Init UI elements
        bannerBox.alpha = 0.0
        bannerLabel.preferredMaxLayoutWidth = UIScreen.main.bounds.width - 60 // Padding and cancel button\
        searchBox.alpha = 0.0
        
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
    
    func suspendAutoSearch( message: String ) {
        DispatchQueue.main.async {
            self.searchOnRegionChange = false
            self.searchLabelButton.titleLabel!.text = message
            self.searchBox.layoutIfNeeded()
            self.searchBox.fadeIn()
        }
    }
    
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
            self._add(marks:marks)
        }
    }
    
    private func _add( marks: [Mark] ) {
        mapView.addAnnotations(marks)
    }
    
    func remove(marks: [Mark]) {
        DispatchQueue.main.async {
            self._remove(marks: marks)
        }
    }
    
    private func _remove( marks: [Mark] ) {
        mapView.removeAnnotations(marks)
    }
    
    func select(mark: Mark) {
        DispatchQueue.main.async {
            self.mapView.selectAnnotation(mark, animated: true)
        }
    }
    
    func center( mark: Mark ) {
        forceRefreshOnRegionChange = true
        DispatchQueue.main.async {
            self.mapView.setCenter(mark.coordinate, animated: true)
            self.mapView.selectAnnotation(mark, animated: true)
        }
    }
    
    // MAP REGION CHANGES IF setRegion:Bool is set
    //This method will instruct the mapView to display the passed marks.
    // It will only add new Marks and it will remove any marks of the specified kind
    // that are not in the passed array.
    func display( marks: [Mark], kind: Mark.Kind, setRegion: Bool) {
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
        
        DispatchQueue.main.async {
            self._remove( marks: invalidMarks )
            self._add( marks: newMarks )
        
            if setRegion {
                self.mapView.showAnnotations(marks, animated: true)
                self.updateUI()
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

    // The selectedMarkView might need to be redrawn if its favorite status changed.
    //  The showFavoritesButton is shown if there are favorites.
    override func viewDidAppear(_ animated: Bool) {
        selectedMarkView?.prepareForDisplay()
        
        // Should the stops be refreshed?
        if forceRefreshOnAppear {
            forceRefreshOnAppear = false
            refreshStops()
        }
        
        updateUI()

        super.viewDidAppear(animated)
    }
    
    // Called from AppDelegate when App comes back to foreground
    func didBecomeActive() {
        predictionsViewController.reloadPressed( self ) // NOOP if predictions isn't up
        updateUI()
    }
    
    var searchLabelTimer: Timer?
    
    func updateUI() {
        mapView.showsTraffic = UserSettings.shared.showsTraffic

        // Validate user tracking. Access may have changed via in-app settings or directly through Device Settings.
        mapView.showsUserLocation = UserSettings.shared.trackUser && Default.Location.accessible

        // BUTTON BOX
        
        // Hide the location button if any is true:
        //   MapView isn't showing user location (validation above checks both app flag and device privs)
        //   The user location is currently visible
        let hideLocationButton = !mapView.showsUserLocation || mapView.isUserLocationVisible
        let hideFavoriteButton = UserSettings.shared.favoriteIDs.isEmpty
        let hideButtonBox = hideLocationButton && hideFavoriteButton
        
        UIView.animate(withDuration: Default.aniDuration, animations: {() -> Void in
            self.locationButton.isHidden = hideLocationButton
            self.favoriteButton.isHidden = hideFavoriteButton
            self.buttonBox.alpha = hideButtonBox ? 0.0 : 1.0

            self.buttonStack.setNeedsLayout()

        }, completion: nil )
            
        /*
            { (state: Bool) -> Void in
            self.buttonStack.layoutIfNeeded()
            print( "Done: \(self.buttonBox.frame.height), \(self.buttonStack.frame.height)")
        })
        UIView.animate(withDuration: Default.aniDuration) {() -> Void in
            self.locationButton.isHidden = hideLocationButton
            self.favoriteButton.isHidden = hideFavoriteButton
            self.buttonBox.isHidden = hideButtonBox
            self.view.layoutIfNeeded()
        }
*/
        // Note regarding animation of the buttons and its container:
        //   The buttons are inside a stackview which takes care of sizing itself when child objects are added/removed/hidden.
        // At times, the stackView has not resized correctly. This might be due to the stack being hidden when the resize is needed.
        // Added the self.view.layoutIfNeeded() to see if this corrects this.  The problem occurs sporadically.

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
