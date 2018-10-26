//
//  DateParser.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 8/26/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import UIKit

public class DateFactory {

    enum Format:String {
        case deltaMinutes, localTime
    }

    static var format: Format = .deltaMinutes

    // MBTA sends timestamps in this format: "2018-08-26T12:09:51-04:00",
    static let ISOdateFormatter = ISO8601DateFormatter()
    static let dateFormatter = DateFormatter()

}

public extension NSAttributedString {
    public func width(height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect,
                                            options: [.usesLineFragmentOrigin, .usesFontLeading],
                                            context: nil)
        return ceil(boundingBox.height)
    }
}

extension String {
    var asDate: Date? {
        return DateFactory.ISOdateFormatter.date( from: self )
    }
}

extension Date {
    func withms() -> String {
        // Just the local time with milliseconds
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss.SSS"
        return dateFormatter.string(from: self)
    }
    
    func forDisplay() -> NSAttributedString {
        switch DateFactory.format {
        case .deltaMinutes:
            let (string, attributes) = minutesFromNow()
            return NSAttributedString(string: string, attributes: attributes)
            
        default:
            fatalError( "Format not implemented. \(DateFactory.format)" )
        }
    }

    func minutesFromNow() -> (string: String, attributes: AttrDict) {
        let interval = timeIntervalSinceNow
        var plainString = String(Int( interval / 60 ))
        var attrDict = Colors.Times.normal
        
        // Allow one second for processing time.
        if interval < -1 {
            plainString = "Past"
            attrDict = Colors.Times.old
        } else if interval <= 20 {
            plainString = "Now"
            attrDict = Colors.Times.now
        } else if interval < 60 {
            plainString = "\(Int(interval + 0.5)) sec"
            attrDict = Colors.Times.soon
        }
        
        attrDict[NSAttributedString.Key.font] = Default.Font.forTime

        return (plainString, attrDict)
    }
}
