//
//  DebugLogViewController.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 10/8/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import UIKit

public class Debug: UIViewController {
    
    public enum Flag: Int {
        case system, minor, normal, important, error
    }
    
    /***  CLASS DECLARATION ***/
    static var instance: DebugViewController!
    static var debugNavVC: UINavigationController!
    static var mutableText = NSMutableAttributedString()
    
    /** Formatting **/
    static let monoName = "CourierNewPSMT"
    static let monoBoldName = "CourierNewPS-BoldMT"
    static let flaggedAttributes: [[NSAttributedString.Key: Any]] = [
        [ .font: UIFont( name: monoBoldName, size: 10)!, .foregroundColor: UIColor(hex: "000080")],
        [ .font: UIFont( name: monoName, size: 8 )! ],
        [ .font: UIFont( name: monoName, size: 10 )! ],
        [ .font: UIFont( name: monoBoldName, size: 10 )! ],
        [ .font: UIFont( name: monoBoldName, size: 10 )!, .foregroundColor: UIColor.red ]

    ]

    static let spacer = NSAttributedString( string: "\n\n",
                                            attributes: [ .font: UIFont(name:monoName, size:6)! ] )
    
    
    static var dateFormatter = DateFormatter()
    static let dateFormat = "[HH:mm:ss.SSS]\n"
    static var dateString: NSAttributedString {
        return NSAttributedString(string: dateFormatter.string(from: Date()),
                                  attributes: flaggedAttributes[Flag.system.rawValue] )
    }

   static public func log( _ string: String, toConsole: Bool = true , flag: Flag = .normal ) {
        guard instance != nil else {
            print( "DEBUG not setup: \(string)" )
            return
        }
        
        log( NSAttributedString(string: string, attributes: flaggedAttributes[ flag.rawValue ]), toConsole: toConsole )

    }

    static public func log( _ attrString: NSAttributedString, toConsole: Bool = true ) {
        guard instance != nil else {
            print( "DEBUG not setup: \(attrString)" )
            return
        }
        
        mutableText.append( dateString )
        mutableText.append( attrString )
        mutableText.append( spacer )
        
        if toConsole {
            print( attrString.string )
        }
    }
    
    static public func setup( comment: String? = nil ) {
        // set instance here.
        let mainStoryboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        debugNavVC = mainStoryboard.instantiateViewController(withIdentifier: "DebugNavVC") as? UINavigationController
        guard let debugVC = debugNavVC?.viewControllers[0] as? DebugViewController else {
            fatalError( "Cannot access DebugViewController at setup." )
        }
        
        dateFormatter.dateFormat = dateFormat
        instance = debugVC
        
        log(comment ?? "Debug Log Ready")
    }
    
    static public func show( presentingViewController: UIViewController ) {
        guard Thread.isMainThread else {
            fatalError( "Debug.show is not on main thread." )
        }
        
        if debugNavVC.presentingViewController == nil {
            presentingViewController.present(debugNavVC, animated: true, completion: nil)
        }
    }
}

public class DebugViewController: UIViewController {
    @IBOutlet weak var logView: UITextView!
    @IBAction func copyLog(_ sender: Any) {
        Debug.log("Log copied to Clipboard", toConsole: true, flag: .system)
        
        // TODO:  This generates a message to the console.  Why?
        //    2018-10-13 10:53:17.320245-0400 ViciniT[13301:4340526] Returning local object of class NSString
        UIPasteboard.general.string = Debug.mutableText.string

    }
    
    
    @IBAction func donePressed(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        logView.attributedText = Debug.mutableText
        // How to scroll to bottom of list?
        
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
