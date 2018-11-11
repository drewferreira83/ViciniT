//
//  SettingsViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 11/4/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit
import MapKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var trackUserSwitch: UISwitch!
    @IBOutlet weak var subwayButton: UIButton!   // GTFS RouteType of 0 and 1
    @IBOutlet weak var commRailButton: UIButton!
    @IBOutlet weak var busButton: UIButton!
    
    var routeTypes = UserSettings.shared.routeTypes
    
    @IBAction func trackUserChanged(_ sender: UISwitch) {
        UserSettings.shared.trackUser = sender.isOn
    }
    
    @IBAction func routeTypeChanged(_ sender: UIButton) {
        let index = sender.tag
        routeTypes[ index ] = !routeTypes[ index ]

        // Internal GTFS codes 0 and 1 represent the external concept of Subway. The External.Subway button should have a
        // tag of 1, so ensure that routeTypes[0] (GTFS.lightRai) be set to routeTypes[1] (GTFS.subway).
        routeTypes[0] = routeTypes[1]

        UserSettings.shared.routeTypes = routeTypes
        updateImages()

        // Force a reload of stops when we get back to the map.
        MapViewController.shared.refreshStopsOnReturn = true
    }
    
    override func viewDidLoad() {
        trackUserSwitch.isOn = UserSettings.shared.trackUser
        trackUserSwitch.isEnabled = CLLocationManager.locationServicesEnabled()
        updateImages()
        super.viewDidLoad()
    }
    
    func updateImages() {
        let subwayImage = routeTypes[1] ? Images.subwayTrue : Images.subwayFalse
        let commRailImage = routeTypes[2] ? Images.commRailTrue : Images.commRailFalse
        let busImage = routeTypes[ 3 ] ? Images.busTrue : Images.busFalse
        subwayButton.setImage(subwayImage, for: .normal)
        commRailButton.setImage( commRailImage, for: .normal)
        busButton.setImage(busImage, for: .normal)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
