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
        switch modeSegmentedControl.selectedSegmentIndex {
        case 0:
            // Subway
            remove(asChildViewController: collectionVC)
            add(asChildViewController: tableVC)
            break
        case 1:
            // Commuter Rail
            break
        case 2:
            // Bus
            remove(asChildViewController: tableVC)
            add(asChildViewController: collectionVC)
            break
        default:
            fatalError( "Illegal mode index." )
        }
    }

    var collectionVC: RouteCollectionViewController!
    var tableVC: RouteTableViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        collectionVC = storyboard.instantiateViewController(withIdentifier: "RouteCollectionVC") as? RouteCollectionViewController
        tableVC = storyboard.instantiateViewController(withIdentifier: "RouteTableVC") as? RouteTableViewController
        
        add(asChildViewController: tableVC)
        
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
