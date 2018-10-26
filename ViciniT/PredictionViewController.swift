//
//  PredictionViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/30/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit

class PredictionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // This favoriteButton is different from the one on the main mapView.
    @IBOutlet weak var toggleFavoriteButton: UIButton!
    @IBOutlet weak var predictionTable: UITableView!

    @IBAction func donePressed(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // The user toggled the favorite in the Nav Controller of the Predictions View.
    @IBAction func toggleFavorite(_ sender: Any) {
        stop.isFavorite = !stop.isFavorite
        updateFavoriteButton()
    }
    
    @IBAction func reloadPressed(_ sender: Any) {
        // Get predictions
        let query =  Query(kind: .predictions, data: stop )
        query.resume()
    }
    
    var offScreenFrame: CGRect!
    var onScreenFrame: CGRect!
    var stop: Stop = Stop.Unknown
    
    // Predictions should already be sorted by route and departure time.
    // Currently discarding arrival times...
    //
    // Each section has a RoutePredction object.
    var predsByRoute = [RoutePrediction]()
    
    func setPredictions( _ predictions: [Prediction], for stop: Stop) {
        self.stop = stop
        navigationItem.title = stop.name
        
        predsByRoute.removeAll()
        
        for prediction in predictions {
            if let routePrediction = predsByRoute.search(routeID: prediction.routeID) {
                if routePrediction.countOf(direction: prediction.dir) <= 4 {
                    routePrediction.add(prediction)
                }
            } else {
                let newRoutePrediction = RoutePrediction(route: prediction.route)
                newRoutePrediction.add( prediction )
                predsByRoute.append( newRoutePrediction )
            }
        }

        // If the view is onscreen, update the prediction table.
        // If it isn't up, then the update happens during viewWillAppear.
        if view.window != nil {
            predictionTable.reloadData()
        }
        updateFavoriteButton()
    }
    
    func updateFavoriteButton() {
        let img = stop.isFavorite ? Default.Images.favoriteTrue : Default.Images.favoriteFalse
        toggleFavoriteButton.setImage( img, for: .normal)
    }
    /*
    @IBAction func dismissPredictions(_ sender: UIButton ) {
        dismiss( animated: true, completion: nil )
    }
 */
    
    override func viewWillAppear(_ animated: Bool) {
        predictionTable.reloadData()
        predictionTable.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: false)
        super.viewWillAppear(animated)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: nil)
   }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return predsByRoute.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    
        return predsByRoute[section].countBoth
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PredictionCell", for: indexPath) as! PredictionCell
        guard let prediction = predsByRoute[indexPath.section].get(index: indexPath.row) else {
            fatalError( "Couldn't find prediction for \(indexPath)." )
        }

        cell.titleLabel.attributedText = prediction.attributedText
        cell.timeFieldLabel.attributedText = prediction.attributedTime
        cell.backgroundColor = prediction.dir == 0 ? prediction.route.color.lighten() : tableView.backgroundColor

        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect( x: 0, y: 0,
                                         width: tableView.bounds.size.width, height: tableView.sectionFooterHeight) )
        view.backgroundColor = UIColor.black
        return view
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < predsByRoute.count else {
            fatalError( "No route data for prediction section \(section)." )
        }
        
        let route = predsByRoute[section].route
        let label = UILabel(frame: CGRect( x: 0, y: 0,
                width: tableView.bounds.size.width, height: tableView.estimatedSectionHeaderHeight) )
        label.textAlignment = NSTextAlignment.center
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.backgroundColor = route.color
        label.textColor = route.textColor
        label.numberOfLines = 0
        label.font = Default.Font.forPredictionHeader
        label.text = route.fullName

        return label
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < predsByRoute.count else {
            fatalError( "No such section. \(indexPath)")
        }
        
        let predsForRoute = predsByRoute[indexPath.section]
        
        guard let prediction = predsForRoute.get( index: indexPath.row ) else {
            fatalError( "No such row. \(indexPath)")
        }
        
        // As a test, create a vehicle mark and display it.
        if let vehicleID = prediction.vehicleID {
            let query = Query(kind: .vehicles, data: vehicleID )
            query.resume()
        } else {
            Debug.log( "Prediction has no vehicle ID. \(prediction)")
        }
    }

}

//  Supoport to display a Prediction in the tableView.
extension Prediction {
    public var attributedTime: NSAttributedString {
        if let departure = departure {
            return departure.forDisplay()
        }
        
        if let arrival = arrival {
            let prefix = NSMutableAttributedString(string: "Arr: ", attributes:
                [NSAttributedString.Key.font: Default.Font.normal] )
            prefix.append(arrival.forDisplay())
            return prefix
        }
        
        if status.isEmpty {
            return NSAttributedString( string: "Unavailable" )
        }
        
        return( NSAttributedString( string: status ) )
    }
    
    public var attributedText: NSAttributedString {
        if route.isUnknown {
            fatalError( "Accessing direction of unknown route?" )
        }
        
        var toDescription: String!
        
        if trip.isUnknown {
            // For Green Line trains east of Park, the tripID is invalid.
            switch (route.id) {
            case "Green-B":
                toDescription = " to Boston College"
            case "Green-C":
                toDescription = " to Cleveland Circle"
            case "Green-D":
                toDescription = " to Riverside"
            case "Green-E":
                toDescription = " to Heath St"
            default:
                Debug.log( "Getting destination description for an unknown trip on an unexpected route. \(route.id)" )
                toDescription = " ?"
            }
        } else {
            toDescription = " to \(trip.headsign)"
        }
        
        // First line is complete
        let firstLine =  NSMutableAttributedString(string: route.directions[dir] + toDescription,
                                         attributes: [NSAttributedString.Key.font : Default.Font.forDirection])

    
        // COnstruct the second line, if any.
        var statusText = ""
        var trackText = ""
        var comma = ""
        
        // Show the status if there is one
        //   But if both arrival and departure are nil, then don't show it because
        //   the status will appear in the time field.
        if !status.isEmpty && (arrival !=  nil || departure != nil) {
            statusText = status
        }
        
        // Display track number if it exists.
        if let platformCode = stop.platformCode  {
            trackText = "Platform \(platformCode)"
        }
        
        // Nothing in detail?  Return nil
        if statusText.isEmpty && trackText.isEmpty {
            return firstLine
        }
        
        // We need a comma if both status and track are present.
        if !statusText.isEmpty && !trackText.isEmpty {
            comma = ", "
        }
        
        // Return the attributed string with a new line, an indent and the existing data.
        let secondLine = NSAttributedString(string: "\n   " + statusText + comma + trackText,
            attributes: [NSAttributedString.Key.font : Default.Font.forStatus])
        
        firstLine.append(secondLine)
        return firstLine
    }
    
    
}

//  Support to track if the currently loaded stop is a favorite or not.
extension Stop {
    var isFavorite: Bool {
        get {
            return UserSettings.shared.favoriteStops.contains( id )
        }
        
        set (value) {
            if value {
                UserSettings.shared.addFavorite(stop: self)
            } else {
                UserSettings.shared.removeFavorite(stop: self)
            }
        }
    }
}