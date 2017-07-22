//
//  Users.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/4/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

/// User name and location coordinates
/// - Properties:
///     name: user name
///     location: location coordinates

class Users {
    var name: String
    var location: Location
    
    init(name: String) {
        self.name = name
        self.location = Location()
    }
    
    init(name: String, location: Location) {
        self.name = name
        self.location = Location(userName: name, location: location)
    }

    func setLocation(location: Location) {
        self.location.latitude = location.latitude
        self.location.longitude = location.longitude
        
    }
}
