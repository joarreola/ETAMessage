//
//  Poll.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import MapKit
import UIKit
import Messages

/// Poll iCloud for remote User's location record.
/// Request local notifications based on ETA data
///
/// fetchRemote(CLLocationDegrees?, CLLocationDegrees?)
/// pollRemote(Users, Location, MKMapView, EtaAdapter, UILabel)
/// etaNotification(UILabel)

class PollManager {
    private var latitude: CLLocationDegrees?
    private var longitude: CLLocationDegrees?
    private var remoteFound: Bool = false
    public var remoteUserName: String
    private var myLocalPacket: Location
    private var myRemotePacket: Location
    public var myEta: TimeInterval?
    public var myDistance: Double?
    public var etaOriginal: TimeInterval? = 0.0
    public let cloudRemote: CloudAdapter
    static  var enabledPolling: Bool = false
    private let hasArrivedEta: Double = 60.0
    private let localNotification: ETANotifications
    var messagesVC: MSMessagesAppViewController?
    var timer: DispatchSourceTimer?
    private var etaAdapter: EtaAdapter
    
    init(remoteUserName: String) {
        self.latitude = 0.0
        self.longitude = 0.0
        self.remoteUserName = remoteUserName
        self.myEta = 0.0
        self.etaOriginal = 0.0
        self.myDistance = 0.0
        
        //self.cloudRemote  = CloudAdapter(userName: remoteUserName)
        MessagesViewController.UserName = remoteUserName
        self.cloudRemote  = CloudAdapter()
        self.myLocalPacket = Location()
        self.myRemotePacket = Location()
        self.localNotification = ETANotifications()
        self.messagesVC = nil
        self.etaAdapter = EtaAdapter()
    }

    /// Fetch remoteUser's location record from iCloud
    /// - Parameters:
    ///     - whenDone: a closure that returns a Location parameter

    func fetchRemote(userUUID: String, whenDone: @escaping (Location) -> ()) -> () {

        cloudRemote.fetchRecord(userUUID: userUUID) {
            
            (packet: Location) in

            if packet.latitude == nil {

                whenDone(packet)
                
            } else {

                whenDone(packet)
            }
        }
    }


    /// Poll iCloud for remote User's location record.
    /// while-loop runs in a background DispatchQueue.global thread.
    /// MapView updates are done in the DispatchQueue.main thread.
    /// Call etaNotification() to make local notifications posting
    ///     requests based on ETA data.
    /// - Parameters:
    ///     - localUser: local User instance
    ///     - remotePacket: remote location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    ///     - display: UILabel instance display
    
    func pollRemote(localUser: Users, remoteUser: Users, mapView: MKMapView, display: UILabel) {


        // request notification authorization
        localNotification.requestAuthorization()

        // initialize to current local and remote postions
        self.myLocalPacket = Location(userName: localUser.name, location: localUser.location)

        self.myRemotePacket = Location(userName: remoteUser.name, location: remoteUser.location)

        let mapUpdate = MapUpdate();
        
        // etaOriginal
        self.etaOriginal = etaAdapter.getEta()

        let queue = DispatchQueue(label: "edu.ucsc.ETAMessages.timer", attributes: .concurrent)
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .milliseconds(2000))
        
        timer?.setEventHandler(handler: {

                self.myEta = self.etaAdapter.getEta()
                self.myDistance = self.etaAdapter.getDistance()
            
                if self.myEta == nil && self.etaOriginal == nil {
                    self.etaOriginal = 0.0
                } else if self.etaOriginal == 0.0 && self.myEta != nil {
                    self.etaOriginal = self.myEta
                }
    
                /*
                if self.myEta != nil && self.etaOriginal != nil {
                    if self.myEta! != self.etaOriginal!  || Double(self.myEta!) <= self.hasArrivedEta {
                    
                        self.etaNotification(display: display)
                    }
                }
                */

            self.fetchRemote(userUUID: remoteUser.name) {

                    (packet: Location) in
                    
                    if packet.latitude == nil {
                        //print("-- PollManager -- pollRemote() -- DispatchSourceTimer -- self.fetchRemote() -- closure -- returned nil")
                        
                        return
                        
                    }
                    
                    if packet.latitude != self.myRemotePacket.latitude ||
                        packet.longitude != self.myRemotePacket.longitude ||
                        localUser.location.latitude != self.myLocalPacket.latitude ||
                        localUser.location.longitude != self.myLocalPacket.longitude
                    {

                        // update myRemotePacket and myLocalPacket
                        self.myRemotePacket.setLocation(latitude: packet.latitude, longitude: packet.longitude)
                        
                        self.myLocalPacket.setLocation(latitude: localUser.location.latitude, longitude: localUser.location.longitude)

                        self.etaAdapter.getEtaDistance(localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, mapView: mapView, display: display,  etaOriginal: self.etaOriginal!)

                        // UI updates on main thread
                        DispatchQueue.main.async { [weak self ] in
                            
                            if self != nil {
                                
                                mapUpdate.displayUpdate(display: display, localPacket: self!.myLocalPacket, remotePacket: self!.myRemotePacket, eta: true)

                                mapUpdate.addPin(packet: (self?.myRemotePacket)!, mapView: mapView, remove: false)
                                
                                mapUpdate.refreshMapView(localPacket: (self?.myLocalPacket)!, remotePacket: (self?.myRemotePacket)!, mapView: mapView, eta: true)
                            }
                        }
                        
                        // check Userdefaults
                        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
                        let UDRemoteUUID = mySharedDefaults?.object(forKey: "remoteUUID")
                        let UDLatitude = mySharedDefaults?.object(forKey: "latitude")
                        let UDLongitude = mySharedDefaults?.object(forKey: "longitude")
                        print("-- PollManager -- pollRemote -- mySharedDefaults: \n\t remoteUUID: \(String(describing: UDRemoteUUID)) \n\t UDLatitude: \(String(describing: UDLatitude)) \n\t longitude: \(String(describing: UDLongitude))\n")

                        print("-- PollManager -- pollRemote -- remotePacket: \(self.myRemotePacket)\n")
                        

                    } // end of location compare
                } // end of self.fetchRemote()
   

                // ETA == has-arrived, cancel timer
                if self.myEta != nil {
                
                    if (Double(self.myEta!) <= self.hasArrivedEta) || !PollManager.enabledPolling {
                    
                        self.timer?.cancel()

                        UploadingManager.enabledUploading = false
                    }
                }
    
        }) //  end of timer?.setEventHandler(handler)
        
        self.timer?.resume()

    }

    /// Poll UserDefaults for remote User's location record.
    /// while-loop runs in a background DispatchQueue.global thread.
    /// MapView updates are done in the DispatchQueue.main thread.
    /// Call etaNotification() to make local notifications posting
    ///     requests based on ETA data.
    /// - Parameters:
    ///     - localUser: local User instance
    ///     - remotePacket: remote location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    ///     - display: UILabel instance display
    
    func pollUserDefaults(localUser: Users, remoteUser: Users, mapView: MKMapView, display: UILabel) {

        // initialize to current local and remote postions
        self.myLocalPacket = Location(userName: localUser.name, location: localUser.location)
        
        self.myRemotePacket = Location(userName: remoteUser.name, location: remoteUser.location)
        
        let mapUpdate = MapUpdate();
        
        // etaOriginal
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")

        self.etaOriginal = self.etaAdapter.getEta()


        let queue = DispatchQueue(label: "edu.ucsc.ETAMessages.timer", attributes: .concurrent)
        timer?.cancel()
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.scheduleRepeating(deadline: .now(), interval: .seconds(2))
        
        timer?.setEventHandler(handler: {
            
            self.myEta = self.etaAdapter.getEta()
            self.myDistance = self.etaAdapter.getDistance()
            
            if self.myEta == nil && self.etaOriginal == nil {
                self.etaOriginal = 0.0
            } else if self.etaOriginal == 0.0 && self.myEta != nil {
                self.etaOriginal = self.myEta
            }
            if self.etaOriginal != 0.0 {
                mySharedDefaults?.set(self.etaOriginal, forKey: "etaOriginal")
            }
            else {
                self.etaOriginal = mySharedDefaults?.double(forKey: "etaOriginal")
            }
            print("-- PollManager -- pollUserDefaults() -- etaOriginal: \(String(describing: mySharedDefaults?.double(forKey: "etaOriginal")))\n")
            print("-- PollManager -- pollUserDefaults() -- self.etaOriginal: \(String(describing: self.etaOriginal))\n")
            
            if self.myEta != nil && self.etaOriginal != nil {
                if self.myEta! != self.etaOriginal!  || Double(self.myEta!) <= self.hasArrivedEta {
             
                    self.etaNotification(display: display)
                }
             }

            // check UserDefaults
            //let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
            let UDRemoteUUID = mySharedDefaults?.string(forKey: "remoteUUID")

            let UDLatitude = mySharedDefaults?.double(forKey: "latitude")
            let CLLatitude = CLLocationDegrees(String(describing: UDLatitude!))

            let UDLongitude = mySharedDefaults?.double(forKey: "longitude")
            let CLLongitude = CLLocationDegrees(String(describing: UDLongitude!))

            //print("-- PollManager -- pollUserDefaults -- mySharedDefaults: \n\t remoteUUID: \(String(describing: UDRemoteUUID)) \n\t CLLatitude: \(String(describing: CLLatitude)) \n\t CLLongitude: \(String(describing: CLLongitude))\n")

            if Double(String(describing: UDLatitude)) != self.myRemotePacket.latitude ||
                Double(String(describing:UDLongitude)) != self.myRemotePacket.longitude ||
                localUser.location.latitude != self.myLocalPacket.latitude ||
                localUser.location.longitude != self.myLocalPacket.longitude
            {
                    
                // update myRemotePacket and myLocalPacket
                self.myRemotePacket.setLocation(latitude: CLLatitude, longitude:  CLLongitude)
                    
                self.myLocalPacket.setLocation(latitude: localUser.location.latitude, longitude: localUser.location.longitude)
                    
                self.etaAdapter.getEtaDistance(localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, mapView: mapView, display: display,  etaOriginal: self.etaOriginal!)
                    
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                        
                    if self != nil {
                            
                        mapUpdate.displayUpdate(display: display, localPacket: self!.myLocalPacket, remotePacket: self!.myRemotePacket, eta: true)
                            
                        mapUpdate.addPin(packet: (self?.myRemotePacket)!, mapView: mapView, remove: false)
                            
                        mapUpdate.refreshMapView(localPacket: (self?.myLocalPacket)!, remotePacket: (self?.myRemotePacket)!, mapView: mapView, eta: true)
                    }
                }
                    
            } // end of location compare
            
            // ETA == has-arrived, cancel timer
            if self.myEta != nil {
                
                if (Double(self.myEta!) <= self.hasArrivedEta) || !PollManager.enabledPolling {
                    
                    self.timer?.cancel()
                    
                    UploadingManager.enabledUploading = false
                    
                    mySharedDefaults?.set(0.0, forKey: "etaOriginal")
                }
            }
            
        }) //  end of timer?.setEventHandler(handler)
        
        self.timer?.resume()
        
    }

    /// Request local notifications based on ETA data
    /// - Parameters:
    ///     - display: UILabel instance display

    func etaNotification(display: UILabel) {
        //print("-- PollManager -- etaNotification() -- etaOriginal: \(String(describing: self.etaOriginal)) myEta: \(self.myEta!)")
        
        let mapUpdate = MapUpdate()

        switch self.myEta! {
        case (self.etaOriginal! / 4) * 3:

            print("/n=====================================================================")
            print("-- PollManager -- etaNotification -- myEta == etaOriginal/4 * 3")
            print("=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "3/4ths there")
                
                // do an alert
                let alert = UIAlertView()
                alert.title = "ETAMessage"
                alert.message = "\(self.remoteUserName) 3/4ths THERE"
                alert.addButton(withTitle: "OK")
                alert.show()
            }

            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            //setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            

        case (self.etaOriginal! / 4) * 2:
            
            print("/n=====================================================================")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 2")
            print("=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "Half-way there")
                
                // do an alert
                let alert = UIAlertView()
                alert.title = "ETAMessage"
                alert.message = "\(self.remoteUserName) HALF-WAY THERE"
                alert.addButton(withTitle: "OK")
                alert.show()
            }

            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            //setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            

        case (self.etaOriginal! / 4) * 1:
            
            print("/n=====================================================================")
            print("-- PollManager -- etaNotification() -- myEta == etaOriginal/4 * 1")
            print("=====================================================================/n")
            
            // do UI updates in the main thread
            OperationQueue.main.addOperation() {
                mapUpdate.displayUpdate(display: display, localPacket: self.myLocalPacket, remotePacket: self.myRemotePacket, string: "eta:\t\t\((self.myEta!)) sec", secondString: "1/4th there")
                
                // do an alert
                let alert = UIAlertView()
                alert.title = "ETAMessage"
                alert.message = "\(self.remoteUserName) 1/4 THERE"
                alert.addButton(withTitle: "OK")
                alert.show()
            }

            setupLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            //setupPseudoLocalNotification(message: (self.remoteUserName) + " Will arrive in \(self.myEta!) sec")
            

        case 0.0...self.hasArrivedEta:

            print("/n=====================================================================")
            print("-- PollManager -- etaNotification() -- myEta == 0")
            print("=====================================================================/n")
            
            // do UI updates in the main thread
            //OperationQueue.main.addOperation() {
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                
                    mapUpdate.displayUpdate(display: display, localPacket: (self?.myLocalPacket)!, remotePacket: (self?.myRemotePacket)!, string: "eta:\t\t\(String(describing: (self?.myEta!))) sec", secondString: "\(String(describing: self?.remoteUserName)) Has arrived")
                
                    // do an alert
                    let alert = UIAlertView()
                    alert.title = "ETAMessage"
                    alert.message = "\(String(describing: self?.remoteUserName)) HAS ARRIVED"
                    alert.addButton(withTitle: "OK")
                    alert.show()
                }
                
            }

            setupLocalNotification(message: (self.remoteUserName) + " Has arrived")
            //setupPseudoLocalNotification(message: (self.remoteUserName) + " Has arrived")
            
            // reset
            let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
            mySharedDefaults?.set(false, forKey: "enabledPolling")

            
        default: break
            
            //print("-- PollManager -- etaNotification -- default")
        }
    }
    
    /// localNotification()
    
    func setupLocalNotification(message: String) {
        
        print("-- PollManager -- setupLocalNotification()")

        self.localNotification.configureContent(milePost: message)
        
        self.localNotification.registerNotification()
        
        self.localNotification.scheduleNotification()
    }

    /// setupPseudoLocalNotification
    
    func setupPseudoLocalNotification(message: String) {
        
        if messagesVC != nil {
            
            //print("-- PollManager -- etaNotification() -- setupPseudoLocalNotification() -- call: presentViewController()")
            
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    self?.presentViewController(message: (self?.remoteUserName)! + " Has Arrived")
                }
            }
            
        } else {
            //print("-- PollManager -- etaNotification() -- setupPseudoLocalNotification() -- messagesVC == nil")
        }
    }

    /// Note that polling has been enabled
    
    func enablePolling() {
        //print("-- PollManager -- enablePolling")
        
        PollManager.enabledPolling = true
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        mySharedDefaults?.set(true, forKey: "enabledPolling")
    }

    /// Note that polling has been disabled
    
    func disablePolling() {
        //print("-- PollManager -- disablePolling")
        
        PollManager.enabledPolling = false
        
        self.timer?.cancel()
        
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        mySharedDefaults?.set(false, forKey: "enabledPolling")
    }

    /// presentViewController()
    
    func presentViewController(message: String) {
        //print("-- PollManager -- presentViewController() --------------------------")
        var controller: UIViewController!
        
            controller = instantiatePseudoNotificationsViewController(message: message)
        
            self.messagesVC?.addChildViewController(controller)
        
            controller.view.frame = (self.messagesVC?.view.bounds)!
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            self.messagesVC?.view.addSubview(controller.view)
            
            controller.view.leftAnchor.constraint(equalTo: (self.messagesVC?.view.leftAnchor)!).isActive = true
            controller.view.rightAnchor.constraint(equalTo: (self.messagesVC?.view.rightAnchor)!).isActive = true
            controller.view.topAnchor.constraint(equalTo: (self.messagesVC?.view.topAnchor)!).isActive = true
            controller.view.bottomAnchor.constraint(equalTo: (self.messagesVC?.view.bottomAnchor)!).isActive = true
        
            //self?.display.text = self?.message
            //controller.loadView()
            controller.didMove(toParentViewController: self.messagesVC)

    }
    
    /// instantiatePseudoNotificationsViewController()
    
    private func instantiatePseudoNotificationsViewController(message: String) -> UIViewController {
        //print("-- PollManager -- instantiatePseudoNotificationsViewController()")

        guard let controller = self.messagesVC?.storyboard?.instantiateViewController(withIdentifier: "PseudoNotificationsViewController") as? PseudoNotificationsViewController else {
            fatalError("PseudoNotificationsViewController not found")
        }
        controller.message = message
        
        return controller
    }
    
}


