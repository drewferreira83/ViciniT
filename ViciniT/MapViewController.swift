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

    func display( marks: [Mark], kind: Mark.Kind, region: MKCoordinateRegion?, select: Mark?)
    func show( predictions: [Prediction], for stop: Stop )
    func show( routes: [Route], for stop: Stop )
//    func select( mark: Mark )
    
    func getUserLocation() -> CLLocationCoordinate2D?
}

class MapViewController: UIViewController, MapManager {
    
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var buttonBox: UIView!
    
    @IBAction func showFavorites(_ sender: Any) {
        vicinit.showFavorites()
    }
    
    // Recenter the map on the user's location.
    @IBAction func showLocation(_ sender: Any) {
        // We do want a search after the recenter.
        if let newCenter = locMgr.location?.coordinate {
            forceShowStops = true
            mapView.setCenter(newCenter, animated: true)
        }
    }
    
    var scopeLevel: Scope.Level = .normal
    var vicinit: ViciniT!
    
    var selectedMarkView: MarkView?
    var predictionsViewController: PredictionViewController!
    var predictionsNavVC: UINavigationController!
    let locMgr = CLLocationManager()
    
    var userInitiatedRegionChange = false
    var forceShowStops = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*
         Wanted to detect rotation of device to set the visibility of the Show Current Location button.  However, in the closure, the mapView isn't
         reporting on the user's visibility as expected.

        // Detect rotation of device, which might move the user location off screen.
        NotificationCenter.default.addObserver(forName: UIDevice.orientationDidChangeNotification,
                                               object: nil,
                                               queue: .main,
                                               using: { notification in
                                                print( "User visible? \(self.mapView.isUserLocationVisible)")
                                                self.locationButton.isHidden = !self.mapView.showsUserLocation || self.mapView.isUserLocationVisible
        })
         */

        // Start functionality.
        vicinit = ViciniT( mapManager: self )
        mapView.delegate = self
        locationButton.isHidden = true
        
        buttonBox.layer.borderColor = UIColor.black.cgColor
        buttonBox.layer.borderWidth = 1
        buttonBox.layer.cornerRadius = 8
        buttonBox.clipsToBounds = true
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        predictionsNavVC = mainStoryboard.instantiateViewController(withIdentifier: "PredictionsNavVC") as? UINavigationController
        predictionsViewController = predictionsNavVC.viewControllers[0] as? PredictionViewController
    
        locMgr.delegate = self
        locMgr.desiredAccuracy = kCLLocationAccuracyBest
        locMgr.distanceFilter = 50.0
        
        // If app authorization has not been determined, ask for permission from OS
        // Once set, it will remain set until app is deleted.
        
        var startRegion = Default.Map.region
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locMgr.requestWhenInUseAuthorization()

        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
            if let here = locMgr.location?.coordinate {
                // We have the user's location, so overrride teh default start region.
                startRegion = MKCoordinateRegion(center: here, span: Default.Map.span)
            }
            
        default:
            mapView.showsUserLocation = false
        }
        
        mapView.setRegion( startRegion, animated: false )
    }
    
     override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /****  PUBLIC FUNCTIONS  ****/
    
    func getUserLocation() -> CLLocationCoordinate2D? {
        return locMgr.location?.coordinate
    }
/*

    // Display these marks, changing the region if passed, selecting a mark if passed.
    func display( marks: [Mark], region: MKCoordinateRegion? = nil, select: Mark? = nil ) {
        var oldMarks = [Mark]()
        
        for annotation in mapView.annotations {
            if let mark = annotation as? Mark, !mark.isFavorite {
                oldMarks.append( mark )
            }
        }
        
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(oldMarks)
            self.mapView.addAnnotations(marks)

            if let region = region {
                self.mapView.setRegion(region, animated: true)
            }
            

            
            if let selectedMark = select {
                self.mapView.setCenter( selectedMark.coordinate, animated: true )
                self.mapView.selectAnnotation(selectedMark, animated: true)
            }
        }
    }
    */
    
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
    func display( marks: [Mark], kind: Mark.Kind = .all, region: MKCoordinateRegion? = nil, select: Mark? = nil ) {

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
                // Never remove favorite stops.
                if !existingMark.isFavorite && existingMark.kind == kind &&
                    (!marks.contains {
                        mark in
                        return mark == existingMark }) {
                    // Slate this mark to be removed.
                    removeMarks.append( existingMark )
                }
            }
        }
        
        DispatchQueue.main.async {
            self.mapView.removeAnnotations(removeMarks)
            self.mapView.addAnnotations(newMarks)
            
            if let region = region {
                self.mapView.setRegion(region, animated: true)
            }
            
            if let markToSelect = select {
                self.mapView.setCenter( markToSelect.coordinate, animated: true )
                
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
        favoriteButton.isHidden = UserSettings.shared.favoriteStops.isEmpty
    }
    
    // Closing the predictionViewController DOES NOT call this stub.
    @IBAction func returnToMap( _ sender: UIStoryboardSegue? ) {
    }
 
    /*
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear( animated )
        
        let coords = CLLocationCoordinate2D(latitude: 42.351074, longitude: -71.065126)
        let region = MKCoordinateRegion(center: coords, latitudinalMeters: 500, longitudinalMeters: 500 )
        let query = Query(kind: .test, data: region)
        query.resume()
        
        
    }
    */
    
}


