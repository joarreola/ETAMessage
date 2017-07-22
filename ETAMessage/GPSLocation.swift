//
//  GPSLocation.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/7/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/// Helper for CLLocation framework's locationManager() callback
///
/// updateUserCoordinates(Users:, Location)
/// uploadToIcloud(Users)
/// checkRemote(PollManager, Users, Users, MKMapView, display, fetchActivity) -> Bool

class GPSLocationAdapter {

    private var packet: Location
    private var mapUpdate: MapUpdate

    init() {
        self.packet = Location()
        self.mapUpdate = MapUpdate()
    }

    /// Upload a location record to iCloud
    /// - Parameters:
    ///     - user: UUID
    /// - Returns: Location packet uploading outcome: true or false

    func uploadToIcloud(user: Users, whenDone: @escaping (Bool) -> ()) -> () {

        ViewController.UserName = user.name

        let cloud = CloudAdapter()

        cloud.upload(user: user) { (result: Bool) in

            whenDone(result)
        }
    }

    /// Fetch a location record from iCloud
    /// - Parameters:
    ///     - user: UUID
    /// - Returns: Location packet
    
    func fetchFromIcloud(user: Users, whenDone: @escaping (Location) -> ()) -> () {
        
        //ViewController.UserName = user.name
        
        let cloud = CloudAdapter()
        
        cloud.fetchRecord(userUUID: user.name) { (location: Location) in
            
            whenDone(location)
        }
    }

    /// Attempt to fetch remote-User's record, request eta and distance
    /// if fetched.
    /// - Parameters:
    ///     - pollRemoteUser: A PollManager instance
    ///     - localUser: Users instance for local location coordinates
    ///     - remoteUser: Users instance for remote location coordinates
    ///     - mapView: MKMapView instance for mapView updates
    ///     - eta: EtaAdapter instance to make the getEtaDistance() call
    /// - Returns: Location packet fetching outcome: true or false
    /*
    func checkRemote(pollRemoteUser: PollManager, localUser: Users, remoteUser: Users, mapView: MKMapView, display: UILabel, result: @escaping (Bool) -> ()) {

        let mapUpdate = MapUpdate()

        //pollRemoteUser.fetchRemote(fetchActivity: fetchActivity) {
        pollRemoteUser.fetchRemote(userUUID: remoteUser.name) {
            
            (packet: Location) in
            
            if packet.latitude == nil {

                result(false)

            } else {

                // update remoteUser Location
                remoteUser.location = packet
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil && !PollManager.enabledPolling {

                        mapUpdate.addPin(packet: remoteUser.location, mapView: mapView, remove: false)
                    }
                }

                result(true)
            }
        }
    }
    */
    /*
    func handleUploadResult(_ result: Bool, display: UILabel, localUser: Users, remoteUser: Users, mapView: MKMapView, pollManager: PollManager) {

        if !result {

            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil && !PollManager.enabledPolling {
                    
                    self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "upload to iCloud failed")
                }
            }
            
        } else {

            // don't update display for just localUser if polling
            if !PollManager.enabledPolling {

                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                
                    if self != nil {
                    
                        self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "uploaded to iCloud")
                    }
                }
            }
            
            // don't check remote user if polling has net yet been enabled
            if !PollManager.enabledPolling {
                
                return
                
            }

            self.checkRemote(pollRemoteUser: pollManager, localUser: localUser, remoteUser: remoteUser, mapView: mapView, display: display) {
                
                (result: Bool) in

                self.handleCheckRemoteResult(result, display: display, localUser: localUser, remoteUser: remoteUser)
                
            }
        }
    }
    */
    /*
    func handleCheckRemoteResult(_ result: Bool, display: UILabel, localUser: Users, remoteUser: Users) {
        
        if !result {
            
            // failed to fetch RemoteUser's location.
            // Assumed due to Disabled by RemoteUser
            //  - reset poll_entered to 0
            //  - update display
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil && !PollManager.enabledPolling {

                    self?.mapUpdate.displayUpdate(display: display, packet: localUser.location, string: "remote user location not found", secondString: "tap Poll to restart session")
                }
            }
            
            //            self.poll_entered = 0
            
        } else {
            
            // update display to include remotePacket and eta data
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil && !PollManager.enabledPolling {

                    self?.mapUpdate.displayUpdate(display: display, localPacket: localUser.location, remotePacket: remoteUser.location, eta: true)
                }
            }
        }
    }
    */


}
