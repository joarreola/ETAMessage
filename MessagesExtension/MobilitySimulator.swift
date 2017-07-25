//
//  MobilitySimulator.swift
//  ETAMessages
//
//  Created by taiyo on 6/21/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import MapKit

class MobilitySimulator {
    static var mobilitySimulatorEnabled: Bool = false
    private let deltaLatitude = 0.09
    private let deltaLongitude = 0.10
    private var timer: DispatchSourceTimer?
    private var gpsLocation: GPSLocationAdapter
    private var mapUpdate: MapUpdate
    private var origLocation: Location
    private var tempUser: Users

    
    init(userName: String) {
        self.gpsLocation = GPSLocationAdapter()
        self.mapUpdate =  MapUpdate()
        self.origLocation = Location()
        self.tempUser = Users(name: userName)
    }
    
    func startMobilitySimulator(user: Users, display: UILabel, mapView: MKMapView, remote: Bool) {

        MobilitySimulator.mobilitySimulatorEnabled = true
        UploadingManager.enabledUploading = false

        // subtract 0.20 from longitude
        self.origLocation.latitude = user.location.latitude!
        self.origLocation.longitude = user.location.longitude!

        self.mapUpdate.displayUpdate(display: display, localPacket: self.origLocation, remotePacket: self.origLocation, string: "Simulation: Active")

        tempUser = Users(name: user.name)
        //tempUser.location.latitude = user.location.latitude! + deltaLatitude
        tempUser.location.latitude = user.location.latitude!
        tempUser.location.longitude = user.location.longitude! - deltaLongitude
        //tempUser.location.longitude = user.location.longitude!
        
        // update localUser location
        user.location.longitude = user.location.longitude! - deltaLongitude
        self.gpsLocation.uploadToIcloud(user: self.tempUser)  {
            
            (result: Bool) in
            print("-- MobilitySimulator -- self.gpsLocation.uploadToIcloud(user: self.tempUser) -- result: \(result)\n")
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {

                    self?.mapUpdate.displayUpdate(display: display, localPacket: (self?.origLocation)!, remotePacket: (self?.tempUser.location)!, string: "Simulation: Active")
    
                }
            }
        }

        /**
         *
         * Below code runs in a separate thread
         *
         */
        
        let queue = DispatchQueue(label: "edu.ucsc.ETAMessages.timer", attributes: .concurrent)
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(10))

        timer?.setEventHandler(handler: {

            print("-- MobilitySimulator -- call: self.gpsLocation.uploadToIcloud(user: self.tempUser) -- self.tempUser: \(self.tempUser)\n")

            self.gpsLocation.uploadToIcloud(user: self.tempUser) {

                (result: Bool) in

                if !result {

                    // UI updates on main thread
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil && !PollManager.enabledPolling {
                           
                            self?.mapUpdate.displayUpdate(display: display, localPacket: (self?.origLocation)!, remotePacket: (self?.tempUser.location)!, string: "Simulation: upload to iCloud failed")
                            
                            self?.mapUpdate.refreshMapView(packet: (self?.tempUser.location)!, mapView: mapView)
                            
                        }
                    }
                    
                } else {

                    // UI updates on main thread
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil && !PollManager.enabledPolling {
                        
                            print("-- MobilitySimulator -- call self?.mapUpdate.displayUpdate() -- self?.tempUser.location: \(String(describing: self?.tempUser.location))\n")

                            self?.mapUpdate.displayUpdate(display: display, localPacket: (self?.origLocation)!, remotePacket: (self?.tempUser.location)!, string: "Simulation: uploaded to iCloud")
                            
                            self?.mapUpdate.refreshMapView(packet: (self?.tempUser.location)!, mapView: mapView)

                        }  else if self != nil && remote {

                                self?.mapUpdate.addPin(packet: user.location, mapView: mapView, remove: false)
                        }
                    }
                    
                    // get closer
                    if Double(self.tempUser.location.longitude!) + 0.005 > Double(self.origLocation.longitude!) {
                        
                        //self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.0025
                        self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.00025
                        user.location.longitude = user.location.longitude! + 0.00025

                    } else {
                        
                        self.tempUser.location.longitude = self.tempUser.location.longitude! + 0.005
                        user.location.longitude = user.location.longitude! + 0.005
                    }

                    // check if there
                    if Double(self.tempUser.location.longitude!) >= Double(self.origLocation.longitude!) || MobilitySimulator.mobilitySimulatorEnabled == false {

                        self.timer?.cancel()

                        DispatchQueue.main.async { [weak self ] in

                            if self != nil && !PollManager.enabledPolling {

                                self?.mapUpdate.displayUpdate(display: display, localPacket: (self?.origLocation)!, remotePacket: (self?.tempUser.location)!, string: "Simulation: completed")
                            }
                        }

                        MobilitySimulator.mobilitySimulatorEnabled = false
                        
                        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
                        mySharedDefaults?.set(false, forKey: "mobilitySimulatorEnabled")
                    }
                }
            }

        }) //  end of timer?.setEventHandler(handler)

        self.timer?.resume()

    }

    func stopMobilitySimulator() {

        MobilitySimulator.mobilitySimulatorEnabled = false
        
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        mySharedDefaults?.set(false, forKey: "mobilitySimulatorEnabled")
    }

}
