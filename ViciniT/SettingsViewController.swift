//
//  SettingsViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 11/4/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit
import MapKit
import WebKit
import MessageUI

class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var trackUserSwitch: UISwitch!
    @IBOutlet weak var subwayButton: UIButton!   // GTFS RouteType of 0 and 1
    @IBOutlet weak var commRailButton: UIButton!
    @IBOutlet weak var busButton: UIButton!
    @IBOutlet weak var feedbackButton: UIButton!
    @IBOutlet weak var infoWebView: WKWebView!
    @IBOutlet weak var showTrafficSwitch: UISwitch!
    
    @IBAction func modalDismissed(_ sender: UIStoryboardSegue) {
        print( "modal was dismissed.")
    }
    
    var routeTypes = UserSettings.shared.routeTypes
    
    @IBAction func feedbackButtonPressed(_ sender: Any) {
        // Open mail window.
        if MFMailComposeViewController.canSendMail() {
            //let appName = Bundle.main.infoDictionary!["CFBundleName" <<NOT SURE
            let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "No ShortVersionString?"
            let appBuild = Bundle.main.infoDictionary!["CFBundleVersion"] as? String ?? "No Version?"
            
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["drewferreira83@gmail.com"])
            mail.setSubject("About ViciniT \(appVersion)")
            mail.setMessageBody("Build: \(appBuild)<p>", isHTML: true)
            present(mail, animated: true)
        } else {
            // show failure alert
            
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func trackUserChanged(_ sender: UISwitch) {
        UserSettings.shared.trackUser = sender.isOn
    }
    
    @IBAction func showTrafficChanged(_ sender: UISwitch) {
        UserSettings.shared.showsTraffic = sender.isOn
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
        MapViewController.shared.forceRefreshOnAppear = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Enabled the Feedback button only if the mail sysytem is available
        feedbackButton.isEnabled = MFMailComposeViewController.canSendMail()
        
        // Enable the track user button only if User has given permission to location
        // Turn the switch on only if we have permission and the user flag is set.
        trackUserSwitch.isEnabled = Default.Location.accessible
        trackUserSwitch.isOn = Default.Location.accessible && UserSettings.shared.trackUser
        
        showTrafficSwitch.isOn = UserSettings.shared.showsTraffic

        updateImages()
        super.viewWillAppear(animated)
    }
    
    override func viewDidLoad() {
        if let localFile = Bundle.main.url(forResource: "ViciniTHelp", withExtension: "rtf", subdirectory: nil, localization: nil) {
            let myRequest = NSURLRequest(url: localFile) as URLRequest
            infoWebView.load(myRequest)
        } else {
            Debug.log("Couldn't load Help file!", flag: .important )
        }
        
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


}
