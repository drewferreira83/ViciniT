//
//  HasID.swift
//  ViciniT
//
//  Created by Andrew Ferreira on 9/7/18.
//  Copyright © 2018 Andrew Ferreira. All rights reserved.
//

import Foundation

open class HasID: Hashable, CustomStringConvertible {
    fileprivate var _id: String
    
    public var id: String {
        return _id
    }
    
    init( id: String ) {
        _id = id
    }
    
    public var hashValue: Int {
        return _id.hashValue
    }
    
    public var hash: Int {
        return _id.hash
    }
    
    public var description: String {
        return( "[HasID:\(_id)]")
    }
}

public func ==( lhs: HasID, rhs: HasID ) -> Bool {
    return( lhs._id == rhs._id )
}
