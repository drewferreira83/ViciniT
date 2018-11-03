//
//  InfoViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 9/29/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit
import WebKit

class InfoViewController: UIViewController {
    @IBOutlet weak var infoTextView: UITextView!
    @IBOutlet weak var infoWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let localFile = Bundle.main.url(forResource: "ViciniTHelp", withExtension: "rtf", subdirectory: nil, localization: nil) {
            let myRequest = NSURLRequest(url: localFile) as URLRequest
            infoWebView.load(myRequest)
        } else {
            Debug.log("Couldn't load Help file!", flag: .important )
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

    @IBAction func unwindToInfo(sender: UIStoryboardSegue) {
        
    }
    
}
