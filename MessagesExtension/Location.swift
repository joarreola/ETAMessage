//
//  Location.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit

/// latitude and longitude location coordinates
///
/// location { set }

struct Location {
    var latitude: CLLocationDegrees?
    var longitude: CLLocationDegrees?
    var userName: String

    init() {
        self.latitude = 0.0
        self.longitude = 0.0
        self.userName = ""
    }
    
    init(userName: String, location: Location) {
        self.userName = userName
        self.latitude = location.latitude
        self.longitude = location.longitude
    }
    
    init(userName: String, location: CLLocation) {
        self.userName = userName
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
    }

    mutating func setLocation(latitude: CLLocationDegrees?, longitude: CLLocationDegrees?) {
        self.latitude = latitude
        self.longitude = longitude
    }
}
