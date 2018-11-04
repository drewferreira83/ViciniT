//
//  SettingsViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 11/4/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet weak var trackUserSwitch: UISwitch!
    @IBOutlet weak var subwayButton: UIButton!
    @IBOutlet weak var commRailButton: UIButton!
    @IBOutlet weak var busButton: UIButton!
    
    
    @IBAction func trackUserChanged(_ sender: UISwitch) {
    }
    
    @IBAction func routeTypeChanged(_ sender: UIButton) {
        if routeTypes == nil {
            routeTypes = Array<Bool>(repeating: true, count: 5)
        }
        
        var index = 0
        
        // Which GTFS mode changed?
        switch sender.tag {
        case 100:   // Subway Button tag
            index = 0  //  GTFS Subway Value
        case 200:   // Commuter Rail tag
            index = 2  //  GTFS Comm Rail Value
        case 300:   // Bus tag
            index = 3  // GFTS Bus Value
        case 400:   // Ferry tag
            index = 4  // GTFS Value
        default:
            fatalError( "Invalid tag in Route Type Button: \(sender)" )
        }
        
        routeTypes![ index ] = !routeTypes![ index ]
        UserSettings.shared.routeTypes = routeTypes
        updateImages()
        
        Query.routeTypes = routeTypes
    }
    
    var routeTypes = UserSettings.shared.routeTypes
    
    override func viewDidLoad() {
        updateImages()
        super.viewDidLoad()
    }
    
    func updateImages() {
        if let routeTypes = routeTypes {
            let subwayImage = routeTypes[0] ? Default.Images.subwayTrue : Default.Images.subwayFalse
            let commRailImage = routeTypes[2] ? Default.Images.commRailTrue : Default.Images.commRailFalse
            let busImage = routeTypes[ 3 ] ? Default.Images.busTrue : Default.Images.busFalse
            subwayButton.setImage(subwayImage, for: .normal)
            commRailButton.setImage( commRailImage, for: .normal)
            busButton.setImage(busImage, for: .normal)
        }
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
