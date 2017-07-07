//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import Messages
import MapKit
import CoreLocation
import UserNotifications


/// Messages Extension View Controller
///
/// locationManager(CLLocationManager, [CLLocation])
/// locationManager(CLLocationManager, NSError)
/// @IBAction func enable(UIBarButtonItem)
/// @IBAction func poll(UIBarButtonItem)
/// @IBAction func disable(UIBarButtonItem)

class MessagesViewController: MSMessagesAppViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    // notifications delegate
    weak var delegate: UNUserNotificationCenterDelegate?

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var display: UILabel!

    // hardcoding for now. But no need to update per device.
    let localUser  = Users(name: "Oscar-iphone")
    let remoteUser = Users(name: "Oscar-ipad")
    static var UserName = "Oscar-iphone"
    
    // can't pass above object to CloudAdapter(), PollManager(), or UploadingManager()
    // thus String literals
    //var cloud = CloudAdapter(userName: "Oscar-iphone") // done in UploadingManager()
    var locationManager = CLLocationManager()
    //var eta = EtaAdapter(). Done in PollManager and GPSLocation.
    var pollManager = PollManager(remoteUserName: "Oscar-ipad")
    var mapUpdate = MapUpdate()
    var uploading = UploadingManager(name: "Oscar-iphone")
    var gpsLocation = GPSLocationAdapter()
    var mobilitySimulator = MobilitySimulator(userName: "Oscar-iphone")
    
    var locPacketUpdated: Bool = false
    static var locationManagerEnabled: Bool = true
    var localUUID: UUID = UUID(uuidString: "49B5E9E4-967F-4CD4-BCD7-B3439715EE58")!
    var remoteUUID: UUID = UUID(uuidString: "49B5E9E4-967F-4CD4-BCD7-B3439715EE58")!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("-- viewDidLoad -----------------------------------------------------")
        
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        self.pollManager.messagesVC = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- viewWillAppear ------------------------------------------------")

    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //print("-- didReceiveMemoryWarning ------------------------------------------------")
    }
    
    // MARK: - Conversation Handling
    
    
    override func willBecomeActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        //print("-- willBecomeActive ------------------------------------------------")
        
        print("-- willBecomeActive -- local UUID: \(conversation.localParticipantIdentifier)")
        self.localUUID = conversation.localParticipantIdentifier
        
        // refresh mapView
        //self.mapUpdate.refreshMapView(packet: self.localUser.location, mapView: self.mapView)

        let controller: UUIDViewController = UUIDViewController()
    
        if presentationStyle == .expanded {

            // recieve side of message in URL
            guard let message = conversation.selectedMessage else {
                fatalError("Message not found")
            }
            
            let components = URLComponents(string: (message.url?.absoluteString)!)
            let queryItem = components?.queryItems?[0]
            
            print("-- willBecomeActive -- queryItem?.value: \(String(describing: queryItem?.value!))")
            
            controller.messageInUrl = (queryItem?.value)!
            remoteUUID = UUID(uuidString: (queryItem?.value)!)!

            print("-- willBecomeActive -- remoteUUID: \(remoteUUID)")

            controller.viewDidLoad()
            
            // start polling if user taps on image
            print("-- willBecomeActive -- call:self.startPolling()")

            self.startPolling()
        }
    }
    
    
    
    override func didResignActive(with conversation: MSConversation) {
        // Called when the extension is about to move from the active to inactive state.
        // This will happen when the user dissmises the extension, changes to a different
        // conversation or quits Messages.
        
        // Use this method to release shared resources, save user data, invalidate timers,
        // and store enough state information to restore your extension to its current state
        // in case it is terminated later.
        print("-- didResignActive -------------------------------------------------")
    }
   
    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        // Called when a message arrives that was generated by another instance of this
        // extension on a remote device.
        
        // Use this method to trigger UI updates in response to the message.
        print("-- didReceive ------------------------------------------------------")
    }
    
    override func didStartSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user taps the send button.
        print("-- didStartSending -------------------------------------------------")
    }
    
    override func didCancelSending(_ message: MSMessage, conversation: MSConversation) {
        // Called when the user deletes the message without sending it.
    
        // Use this to clean up state related to the deleted message.
        print("-- didCancelSending ------------------------------------------------")
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
    
        // Use this method to prepare for the change in presentation style.
        print("-- willTransition to: \(presentationStyle) -------------------------")
        
    }
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called after the extension transitions to a new presentation style.
    
        // Use this method to finalize any behaviors associated with the change in presentation style.
        print("-- didTransition to: \(presentationStyle) --------------------------")
    }
    


    /**
     *
     * Called by the CLLocation Framework on GPS location changes
     *
     */
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        // locationManager(:didUpdateLocations) guarantees that locations will not
        // be empty
        let location = locations.last!
        let lmPacket = Location(userName: "", location: location)
        
        // refresh mapView from locationManager just once
        if !locPacketUpdated
        {
            
            self.localUser.location = lmPacket
            
            self.mapUpdate.refreshMapView(packet: lmPacket, mapView: mapView)

            mapUpdate.displayUpdate(display: display, string: "locationManager...")
            
            locPacketUpdated = true

        }
        
        // abort if disabled
        if !MessagesViewController.locationManagerEnabled {

            return
        }
        
        // nothing to update if same location
        if lmPacket.latitude == localUser.location.latitude &&
            lmPacket.longitude == localUser.location.longitude
        {
            
            return
        }
        
        // A new location: update User's Location object
        print("-- locationManager -- location: '\(location)'")
            
        //gpsLocation.updateUserCoordinates(localUser: localUser, packet: lmPacket)
        self.localUser.location = lmPacket

        if (UploadingManager.enabledUploading) {
            // refresh mapView if enabledUploading
            
            // don't refresh MapView centered on localUser if polling enabled
            if !PollManager.enabledPolling {
                //print("-- locationManager -- refresh mapView for localUser")

                self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
            }

            //print("-- locationManager -- call: self.gpsLocation.uploadToIcloud(user: localUser)")

            self.gpsLocation.uploadToIcloud(user: localUser) {

                (result: Bool) in
                
                self.gpsLocation.handleUploadResult(result, display: self.display, localUser: self.localUser, remoteUser: self.remoteUser, mapView: self.mapView, pollManager: self.pollManager)
            }
        }
    }

 
    @nonobjc func locationManager(manager: CLLocationManager!,
                                  didFailWithError error: NSError!) {
        
        print("-- locationManager -- didFailWithError: \(error.description)")
        let alert: UIAlertControllerStyle = UIAlertControllerStyle.alert
        let errorAlert = UIAlertController(title: "Error",
                                           message: "Failed to Get Your Location",
                                           preferredStyle: alert)
        errorAlert.show(UIViewController(), sender: manager)
        
    }

    /**
     *
     * Called on tap of Enable button
     *
     */
    @IBAction func upload(_ sender: UIBarButtonItem) {

        // Entry point to start uploading the current location to iCloud repository
        
        // reenable in case disabled
        self.locationManager.startUpdatingLocation()
        
        // UUID
        addImage()

        // reset localUser name
        localUser.name = String(describing: self.localUUID)
        localUser.location.userName = String(describing: self.localUUID)

        // Upload localUserPacket to Cloud repository

        self.uploading.uploadLocation(user: localUser) {
            
            (result) in

            if !result {
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {

                        // display localUserPacket and error message
                        self?.uploading.updateMap(display: (self?.display)!, packet: (self?.localUser.location)!, string: "upload to iCloud failed")
                    }
                }

                return
            }
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    // display localUserPacket and error message
                    self?.uploading.updateMap(display: (self?.display)!, packet: (self?.localUser.location)!, string: "uploaded to iCloud")
                                    }
            }

            // this allows for uploading of coordinates on LocalUser location changes
            // in locationManager()
            self.uploading.enableUploading()
        }
        
        // refresh mapView
        self.mapUpdate.refreshMapView(packet: self.localUser.location, mapView: self.mapView)

    }
    
    func addImage() {
        
        print("-- addImage -- self.localUUID: \(self.localUUID)")

        let components = NSURLComponents()
        
        // send side of message in URL
        let queryItem = URLQueryItem(name: "uuid", value: String(describing: self.localUUID))
        
        components.queryItems = [queryItem]
        
        let layout = MSMessageTemplateLayout()
        layout.image = UIImage(named: "applePark.png")
        layout.caption = "UUID"
        
        let message = MSMessage()
        message.url = components.url!
        message.layout = layout
        
        self.activeConversation?.insert(message, completionHandler: { (error: Error?) in

            if error != nil {
                print("-- addImage -- self.activeConversation?.insert() -- error: \(String(describing: error))")
            }
        })
        
        UUIDViewController.uuidIndicator.URLMessage?.text = "LOCAL\n" + "\(String(describing: queryItem.value!))"
    }


    /**
     *
     * Called on tap of Simulate button
     *
     */
    @IBAction func simulate(_ sender: UIBarButtonItem) {

        // reset localUser and remoteUser names to the respective UUID strings
        localUser.name = String(describing: self.localUUID)
        localUser.location.userName = String(describing: self.localUUID)
        remoteUser.name = String(describing: self.remoteUUID)
        remoteUser.location.userName = String(describing: self.remoteUUID)

        // make sure CLLocation doesn't create UI-access contention
        self.locationManager.stopUpdatingLocation()
        MessagesViewController.locationManagerEnabled = false
        
        // 
        mapUpdate.displayUpdate(display: display)
        mapUpdate.addPin(packet: localUser.location, mapView: mapView, remove: true)

        // simulate remote location if polling
        if PollManager.enabledPolling {

            mobilitySimulator.stopMobilitySimulator()

            // remote needs to get back to the original local's location
            remoteUser.location = localUser.location

            mobilitySimulator.startMobilitySimulator(user: remoteUser, display: display, mapView: mapView, remote: true)

        } else {

            mobilitySimulator.startMobilitySimulator(user: localUser, display: display, mapView: mapView, remote: false)
        }
    }

    /**
     *
     * Called on tap of Poll button
     *
     */
    @IBAction func fetch(_ sender: UIBarButtonItem) {
    
        // check for remoteUser record

        self.startPolling()
    }
        
    func startPolling() {
        
        // display localUserPacket
        self.mapUpdate.displayUpdate(display: self.display, packet: self.localUser.location)
        
        // initialize vars for proper restart with a pol retap
        pollManager.disablePolling()
        EtaAdapter.eta = nil
        EtaAdapter.distance = nil
        EtaAdapter.previousDistance = nil
        pollManager.etaOriginal = 0.0
        pollManager.myEta = 0.0
        pollManager.myDistance = 0.0
        
        
        // reset localUser and remoteUser names to the respective UUID strings
        localUser.name = String(describing: self.localUUID)
        localUser.location.userName = String(describing: self.localUUID)
        remoteUser.name = String(describing: self.remoteUUID)
        remoteUser.location.userName = String(describing: self.remoteUUID)

        self.pollManager.fetchRemote(userUUID: String(describing: self.remoteUUID)) {

            (packet: Location) in
            
            if packet.latitude == nil {
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        // display localUserPacket
                        self?.mapUpdate.displayUpdate(display: (self?.display)!, packet: (self?.localUser.location)!, string: "fetchRemote failed")
                    }
                }
                
                // reset poll_entered to get a chance to recheck for remoteRecord before
                // calling pollManager.pollRemote(), which polls for the record
                // But, could instead let pollManager.pollRemote() to exit after N (10?)
                // retries?
                //self.poll_entered = 0;

            } else {

                // update remoteUser Location
                self.remoteUser.location.setLocation(latitude: packet.latitude!, longitude: packet.longitude!)
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        // note coordinates set on display
                        self?.mapUpdate.displayUpdate(display: (self?.display)!, localPacket: (self?.localUser.location)!, remotePacket: packet)
                    }
                }

                self.pollManager.pollRemote(localUser: self.localUser, remoteUser: self.remoteUser, mapView: self.mapView, display: self.display)
                
                
                // enable in case stationary user moves during or after polling
                //but not if simulator is running
                if !MobilitySimulator.mobilitySimulatorEnabled {
                    self.locationManager.startUpdatingLocation()
                    self.uploading.enableUploading()
                }
            }
            
            // should polling be enabled here or outside self.pollManager.fetchRemote()?
            self.pollManager.enablePolling()
        }
    }
  
    /**
     *
     * Called on tap of Disable button
     *
     */
    @IBAction func disable(_ sender: UIBarButtonItem) {

        // Remove location record from iCloud repository.

        // reset localUser and remoteUser names to the respective UUID strings
        localUser.name = String(describing: self.localUUID)
        localUser.location.userName = String(describing: self.localUUID)
        remoteUser.name = String(describing: self.remoteUUID)
        remoteUser.location.userName = String(describing: self.remoteUUID)
        
        // remove cloud record
        pollManager.cloudRemote.deleteRecord(userUUID: localUser.name)
        pollManager.cloudRemote.deleteRecord(userUUID: remoteUser.name)
        
        // clear display
        mapUpdate.displayUpdate(display: display)
        
        mapUpdate.addPin(packet: localUser.location, mapView: mapView, remove: true)
        
        // refresh mapView for possible poll use
        self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
        
        // stop location updates as this path is for the stationary user
        self.locationManager.stopUpdatingLocation()

        uploading.disableUploading()
        pollManager.disablePolling()
        mobilitySimulator.stopMobilitySimulator()
        EtaAdapter.eta = nil
        EtaAdapter.distance = nil
        pollManager.etaOriginal = 0.0
        pollManager.myEta = 0.0
        pollManager.myDistance = 0.0
        
        // cleanup display
        self.mapUpdate.refreshMapView(packet: localUser.location , mapView: mapView)
        
        mapUpdate.displayUpdate(display: display, string: "locationManager...")
        
    }

}

