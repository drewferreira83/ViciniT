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

   static public func log( _ string: String, flag: Flag = .normal ) {
        log( NSAttributedString(string: string, attributes: flaggedAttributes[ flag.rawValue ]) )
    }

    static public func log( _ attrString: NSAttributedString ) {
        mutableText.append( dateString )
        mutableText.append( attrString )
        mutableText.append( spacer )
  
        #if DEBUG
        print( attrString.string )
        #endif
    }
    
 
}
