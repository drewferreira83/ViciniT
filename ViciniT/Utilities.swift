//
//  Utilities.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 12/28/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation
import UIKit
import MapKit


extension UIColor {
    convenience init(hex: String, alpha: CGFloat = 1.0) {
        guard let rgb = UInt(hex, radix: 16) else {
            fatalError( "Expected a hex value for a color.  Got \(hex)")
        }
        
        self.init(
            red: CGFloat((rgb & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgb & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgb & 0x0000FF) / 255.0,
            alpha: CGFloat(alpha)
        )
    }
    
    func lighten() -> UIColor {
        //  Map the RGB values proportionately to [low...1.0]
        let low: CGFloat = 220 / 255
        let range: CGFloat  = 1 - low
        
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let newR = low + range * r
        let newG = low + range * g
        let newB = low + range * b
        
        return( UIColor(red: newR, green: newG, blue: newB, alpha: a))
        
    }
    
}



// Support to allow view borders to be set in Xcode IB.
@IBDesignable extension UIView {
    @IBInspectable var borderColor: UIColor? {
        set {
            layer.borderColor = newValue?.cgColor
        }
        get {
            guard let color = layer.borderColor else {
                return nil
            }
            return UIColor(cgColor: color)
        }
    }
    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }
    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
            clipsToBounds = newValue > 0
        }
        get {
            return layer.cornerRadius
        }
    }
}

extension MKCoordinateRegion {
    public func contains( _ coord: CLLocationCoordinate2D ) -> Bool {
        let latInRange = abs(center.latitude - coord.latitude) <= span.latitudeDelta / 2
        let lngInRange = abs(center.longitude - coord.longitude) <= span.longitudeDelta / 2
        
        return latInRange && lngInRange
    }
}

extension UIView {
    /// Fade in a view with a duration
    ///
    /// Parameter duration: custom animation duration
    func fadeIn(withDuration duration: TimeInterval = 1.0) {
        if alpha == 0.0 {
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 1.0
            })
        }
    }
    
    /// Fade out a view with a duration
    ///
    /// - Parameter duration: custom animation duration
    func fadeOut(withDuration duration: TimeInterval = 1.0) {
        if alpha != 0.0 {
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 0.0
            })
        }
    }
}
