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
        //print("-- EtaAdapter -- viewDidLoad() -----------------------------")

        // to hold progress and label
        CloudAdapter.cloudIndicator.fetchActivity = self.fetchActivity
        CloudAdapter.cloudIndicator.uploadActivity = self.uploadActivity
        
    }
    
    /// Fetch a location record from iCloud. Delete if found, then save.
    /// - Parameters:
    ///     - userUUID: UUID for remote user (passed in UUID image)
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
        //var recordToSave: CKRecord = CKRecord(recordType: "Location", recordID: locationRecordID)
        locationRecord["Location"] = user.location as? CKRecordValue
        recordToSave = locationRecord

        //let myContainer: CKContainer = CKContainer.default()
        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        publicDatabase.fetch(withRecordID: locationRecordID) {

            (record, error) in

            if let error = error {
                // filter out "Record not found"
                print("-- upload() -- publicDatabase.fetch -- closure -- Error: \(locationRecordID): \(error)\n")

                self.recordFound = false
            }

            if record == nil {
                
                recordToSave = locationRecord
                
            } else {
                print("-- CloudAdapter -- upload() -- publicDatabase.fetch -- closure -- found -- record: \(String(describing: record))\n")
                
                self.recordFound = true
                
                //record.setObject(aValue, forKey: attributeToChange)
                record?.setObject(user.location.latitude! as CKRecordValue, forKey: "latitude")
                record?.setObject(user.location.longitude! as CKRecordValue, forKey: "longitude")
                recordToSave = record!
                
            }

            // call save() method while in the fetch closure
            print("-- CloudAdapter -- upload() -- publicDatabase.save -- recordToSave: \(recordToSave)\n")
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
                    print("-- CloudAdapter -- upload() -- publicDatabase.save -- closure -- Error: \(recordToSave): \(String(describing: error))\n")

                    self.recordSaved = false
                    
                    // callback to the passed closure

                    whenDone(self.recordSaved)

                    return
                }
                print("-- CloudAdapter -- upload() -- publicDatabase.save -- record saved: \(String(describing: record))")

                self.recordSaved = true
                
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
        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        let predicate =  NSPredicate(format: "recordID = %@", CKRecordID(recordName: userUUID))
        let locationSubscription = CKQuerySubscription(recordType: "Location", predicate: predicate, options: CKQuerySubscriptionOptions.firesOnRecordUpdate)
        
        let locationNotificationInfo = CKNotificationInfo()
        
        locationNotificationInfo.shouldSendContentAvailable = true
        
        locationNotificationInfo.shouldBadge = false
        
        locationNotificationInfo.alertBody = "Record Updated"
        
        locationSubscription.notificationInfo = locationNotificationInfo
        
        /*
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
        */
        publicDatabase.save(locationSubscription, completionHandler:
            
            ({returnRecord, error in
    
            if let err = error {
                print("-- CloudAdapter -- subscribe() --  publicDatabase.save(locationSubscription) -- closure -- err: \(err.localizedDescription)\n")
                
                return
                
            }
            DispatchQueue.main.async() {
                print("-- CloudAdapter -- subscribe() --  publicDatabase.save(locationSubscription) -- closure -- returnRecord: \(String(describing: returnRecord))\n")
                
                    return
            }
        }))
    }
    
    /// Remove all subscriptions
    /// - Parameters:
    ///     -
    func removeAllSubscriptions() {
        print("-- CloudAdapter -- removeAllSubscriptions()\n")

        //let myContainer: CKContainer = CKContainer.default()
        let myContainer: CKContainer = CKContainer.init(identifier: "iCloud.edu.ucsc.ETAMessages.MessagesExtension")
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        let semaphore = DispatchSemaphore(value: 0)

        // get subscriptions
        publicDatabase.fetchAllSubscriptions() {
            
            (subscriptions, error) in
    
            if let err = error {
        
                print("-- CloudAdapter -- removeAllSubscriptions() -- publicDatabase.fetchAllSubscriptions() -- closure -- err: \(err)\n")
    
            } else {
    
                for subscription in subscriptions! {
                    publicDatabase.delete(withSubscriptionID: String(describing: subscription)) {
                        
                        (string, error) in
    
                        if let err = error {

                            print("-- CloudAdapter -- removeAllSubscriptions() -- publicDatabase.delete(withSubscriptionID) -- closure -- err: \(String(describing: err))\n")
                            
                            return
                        }
                        print("-- CloudAdapter -- removeAllSubscriptions() -- publicDatabase.delete(withSubscriptionID) -- closure -- string: \(String(describing: string))\n")
                        
                        semaphore.signal()
                    }
                    semaphore.wait()
                }
            }
        }
    }

}

