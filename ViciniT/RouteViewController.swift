//
//  RouteViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 1/10/19.
//  Copyright © 2019 Andrew Ferreira. All rights reserved.
//

import UIKit

class RouteViewController: UIViewController {
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var modeSegmentedControl: UISegmentedControl!
    
    @IBAction func modeChanged(_ sender: Any) {
        let newVC = routeViewControllers[ modeSegmentedControl.selectedSegmentIndex ]
        add(asChildViewController: newVC)
        remove(asChildViewController: current)
        current = newVC
    }

    var current: UIViewController!
    var routeViewControllers: [UIViewController]!

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bus = storyboard.instantiateViewController(withIdentifier: "RouteCollectionVC") as! RouteCollectionViewController
        let rail = storyboard.instantiateViewController(withIdentifier: "RouteTableVC") as! RouteTableViewController
        let subway = storyboard.instantiateViewController(withIdentifier: "RouteTableVC") as! RouteTableViewController
        
        bus.data = Session.routes[MBTA.RouteType.bus]
        subway.data = Session.routes[MBTA.RouteType.subway]
        rail.data = Session.routes[MBTA.RouteType.commuterRail]
        
        routeViewControllers = [subway, rail, bus]
        
        current = subway
        add(asChildViewController: subway)
    }
    
    private func remove(asChildViewController viewController: UIViewController) {
        // Notify Child View Controller
        viewController.willMove(toParent: nil)
        
        // Remove Child View From Superview
        viewController.view.removeFromSuperview()
        
        // Notify Child View Controller
        viewController.removeFromParent()
    }
    
    private func add(asChildViewController viewController: UIViewController) {
        
       addChild( viewController )
        
        // Add Child View as Subview
        container.addSubview(viewController.view)
        
        // Configure Child View
        viewController.view.frame = container.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Notify Child View Controller
        viewController.didMove(toParent: self)
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
