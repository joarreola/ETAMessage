//
//  Cloud.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/22/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

struct CloudIndicator {
    var fetchActivity: UIActivityIndicatorView? = nil
    var uploadActivity: UIActivityIndicatorView? = nil
}

/// Manage iCloud record accesses.
///
/// upload(Location)
/// fetchRecord(CLLocationDegrees?, CLLocationDegrees?)
/// deleteRecord()

class CloudAdapter: UIViewController {
    
    private var recordSaved: Bool = false
    private var recordFound: Bool = false
    private var user: String = ""

    @IBOutlet weak var fetchLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!
    @IBOutlet weak var fetchActivity: UIActivityIndicatorView!
    @IBOutlet weak var uploadActivity: UIActivityIndicatorView!

    static var cloudIndicator = CloudIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print("-- CloudAdapter -- viewDidLoad() -----------------------------")

        // to hold progress and label
        CloudAdapter.cloudIndicator.fetchActivity = self.fetchActivity
        CloudAdapter.cloudIndicator.uploadActivity = self.uploadActivity

    }
    
    /// Fetch a location record from iCloud. Delete if found, then save.
    /// - Parameters:
    ///     - userUUID: UUID for remote user
    ///     - whenDone: a closure that takes in a Location parameter

    func fetchRecord(userUUID: String, whenDone: @escaping (Location) -> ()) -> () {

        // UI updates on main thread
        DispatchQueue.main.async { [weak self ] in
            
            if self != nil {
                
                CloudAdapter.cloudIndicator.fetchActivity?.startAnimating()
            }
        }

        // do here instead
        let locationRecordID: CKRecordID = CKRecordID(recordName: userUUID)
        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase
    
        publicDatabase.fetch(withRecordID: locationRecordID) {

            (record, error) in
    
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    
                    CloudAdapter.cloudIndicator.fetchActivity?.stopAnimating()
                }
            }

            if let error = error {
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ()  -- publicDatabase.fetch() -- closure -- Error: \(locationRecordID): \(error)\n")
    
                self.recordFound = false
    
                // callback to the passed closure

                var packet: Location = Location()
                packet.setLocation(latitude: nil,longitude: nil)
                
                whenDone(packet)
    
                return
            }

            let latitude = record?["latitude"] as? CLLocationDegrees
            let longitude = record?["longitude"] as? CLLocationDegrees
            self.recordFound = true
    
            // callback to the passed closure

            var packet: Location = Location()
            packet.setLocation(latitude: latitude, longitude: longitude)

            whenDone(packet)
        }
    }

    /// Delete location record from iCloud
    /// - Parameters:
    ///     - userUUID: String representation of a message user's UUID

    func deleteRecord(userUUID: String) {

        // do here instead
        let locationRecordID: CKRecordID = CKRecordID(recordName: userUUID)
        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        publicDatabase.delete(withRecordID: locationRecordID) {

            (record, error) in

            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Error: \(locationRecordID): \(error)\n")
            }
        }
    }

    /// Upload a location record to iCloud. Delete then save.
    /// - Parameters:
    ///     - user: a Users instance
    ///     - whenDone: a closure that takes in a Location parameter

    func upload(user: Users, whenDone: @escaping (Bool) -> ()) -> () {

        // Called by enable() @IBAction function
        
        var recordToSave: CKRecord
        
        // UI updates on main thread
        DispatchQueue.main.async { [weak self ] in
            
            if self != nil {
                
                CloudAdapter.cloudIndicator.uploadActivity?.startAnimating()
            }
        }

        // do here instead
        let locationRecordID: CKRecordID = CKRecordID(recordName: user.name)
        let locationRecord: CKRecord = CKRecord(recordType: "Location", recordID: locationRecordID)
        locationRecord["Location"] = user.location as? CKRecordValue
        recordToSave = locationRecord

        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        publicDatabase.fetch(withRecordID: locationRecordID) {

            (record, error) in

            if let error = error {
                // filter out "Record not found"
                print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.fetch -- closure -- Error: \(locationRecordID): \(error)\n")

                self.recordFound = false
            }
            
            if record == nil {

                recordToSave = locationRecord

            } else {
                //print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.fetch -- closure -- found -- record: \(String(describing: record))\n")

                self.recordFound = true
                
                //record.setObject(aValue, forKey: attributeToChange)
                record?.setObject(user.location.latitude! as CKRecordValue, forKey: "latitude")
                record?.setObject(user.location.longitude! as CKRecordValue, forKey: "longitude")
                
                recordToSave = record!
            }


            // call save() method while in the fetch closure
            publicDatabase.save(recordToSave) {
    
                (record, error) in

                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        CloudAdapter.cloudIndicator.uploadActivity?.stopAnimating()
                    }
                }

                if error != nil {
                    // filter out "Server Record Changed" errors
                    print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.save -- closure -- Error: \(recordToSave): \(String(describing: error))\n")
    
                    self.recordSaved = false
                    
                    // callback to the passed closure

                    whenDone(self.recordSaved)

                    return
                }

                self.recordSaved = true
                
                //print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.save -- closure -- saved\n")
        
                //print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.save -- closure -- setup subscription -- RecordId: \(locationRecordID)\n")
                
                
                let locationSubscription = CKQuerySubscription(recordType: "Location", predicate: NSPredicate(format: "TRUEPREDICATE"), options: CKQuerySubscriptionOptions.firesOnRecordUpdate)
                
                let locationNotificationInfo = CKNotificationInfo()
                
                locationNotificationInfo.shouldSendContentAvailable = true
                
                locationNotificationInfo.shouldBadge = false
                
                locationNotificationInfo.alertBody = "\(user.name) updated"
                
                locationSubscription.notificationInfo = locationNotificationInfo
/*
                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [locationSubscription], subscriptionIDsToDelete: [])
        
                operation.modifySubscriptionsCompletionBlock = {
                    
                    savedSubscriptions, deletedSubscriptionIDs, operationError in

                    if operationError != nil {
    
                        print("-- ContainerApp -- CloudAdapter -- upload() -- operation.modifySubscriptionsCompletionBlock -- closure -- error: \(String(describing: operationError))\n")

                    } else {

                        print("-- ContainerApp -- CloudAdapter -- upload() -- operation.modifySubscriptionsCompletionBlock -- closure -- Subscribed\n")
                    }
                }
                
                publicDatabase.add(operation)
*/
                publicDatabase.save(locationSubscription) {
                
                    (subscription, error) in
                    
                    if error != nil {
                        print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.save(locationSubscription) -- closure -- error: \(String(describing: error))\n")
                    }
                    else {
                        //print("-- ContainerApp -- CloudAdapter -- upload() -- publicDatabase.save(locationSubscription) -- closure -- saved: \(String(describing: subscription))\n")
                    }
                }
                
                // callback to the passed closure
                whenDone(self.recordSaved)
            }
        }
    }
    
    /// Add a subscription to get a notification on a record change
    /// - Parameters:
    ///     - userUUID: UUID for remote user (passed in UUID image)
    
    func subscribe(userUUID: String) {
        
        //print("-- CloudAdapter -- subscribe() --------------------------------------")
        
        // get record and container
        let locationRecordID: CKRecordID = CKRecordID(recordName: userUUID)
        let locationRecord: CKRecord = CKRecord(recordType: "Location", recordID: locationRecordID)
        let myContainer: CKContainer = CKContainer.default()
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase
        //let sharedDatabase: CKDatabase = myContainer.sharedCloudDatabase
        //print("-- CloudAdapter -- subscribe() -- user: \(userUUID)")
        //print("-- CloudAdapter -- subscribe() -- myContainer: \(myContainer)")
        //print("-- CloudAdapter -- subscribe() -- publicDatabase: \(publicDatabase)")
        
        let locationSubscription = CKQuerySubscription(recordType: "Location", predicate: NSPredicate(format: "TRUEPREDICATE"), options: CKQuerySubscriptionOptions.firesOnRecordCreation)
        
        let locationNotificationInfo = CKNotificationInfo()
        
        locationNotificationInfo.shouldSendContentAvailable = true
        
        locationNotificationInfo.shouldBadge = false
        
        locationNotificationInfo.alertBody = "\(userUUID) updated"
        
        locationSubscription.notificationInfo = locationNotificationInfo
        
        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [locationSubscription], subscriptionIDsToDelete: [])
        
        operation.modifySubscriptionsCompletionBlock = {
            
            savedSubscriptions, deletedSubscriptionIDs, operationError in
            
            if operationError != nil {
                
                print("-- CloudAdapter -- subscribe() -- operation.modifySubscriptionsCompletionBlock -- closure -- error: \(String(describing: operationError))\n")
                
            } else {
                
                print("-- CloudAdapter -- subscribe() -- operation.modifySubscriptionsCompletionBlock -- closure -- Subscribed\n")
            }
        }
        
        publicDatabase.add(operation)
    }
    
}

