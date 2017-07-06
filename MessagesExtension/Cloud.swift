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
        let myContainer: CKContainer = CKContainer.default()
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
                print("-- CloudAdapter -- fetchRecord(whenDone: @escaping (Location) -> ()) -> ()  -- publicDatabase.fetch() -- closure -- Error: \(locationRecordID): \(error)")
    
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

    func deleteRecord(userUUID: String) {

        // do here instead
        let locationRecordID: CKRecordID = CKRecordID(recordName: userUUID)
        let myContainer: CKContainer = CKContainer.default()
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        publicDatabase.delete(withRecordID: locationRecordID) {
            (record, error) in
            if let error = error {
                // Insert error handling
                print("-- CloudAdapter -- deleteRecord() -- self.publicDatabase.delete() -- closure -- Error: \(locationRecordID): \(error)")
                
                return
            }
        }
    }
    

    /// Upload a location record to iCloud. Delete then save.
    /// - Parameters:
    ///     - whenDone: a closure that takes in a Location parameter

    func upload(user: Users, whenDone: @escaping (Bool) -> ()) -> () {

        // Called by enable() @IBAction function
        
        // UI updates on main thread
        DispatchQueue.main.async { [weak self ] in
            
            if self != nil {
                
                CloudAdapter.cloudIndicator.uploadActivity?.startAnimating()
            }
        }

        // do here instead
        let locationRecordID: CKRecordID = CKRecordID(recordName: user.name)
        let locationRecord: CKRecord = CKRecord(recordType: "Location", recordID: locationRecordID)
        let myContainer: CKContainer = CKContainer.default()
        let publicDatabase: CKDatabase = myContainer.publicCloudDatabase

        publicDatabase.delete(withRecordID: locationRecordID) {
            (record, error) in

            if let error = error {
                print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Error: \(locationRecordID): \(error)")

            }

            locationRecord["latitude"]  = user.location.latitude! as CKRecordValue
            locationRecord["longitude"] = user.location.longitude! as CKRecordValue


            // call save() method while in the delete closure
            publicDatabase.save(locationRecord) {
                (record, error) in

                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {
                        
                        CloudAdapter.cloudIndicator.uploadActivity?.stopAnimating()
                    }
                }

                if error != nil {
                    // filter out "Server Record Changed" errors

                    self.recordSaved = false
                    
                    // callback to the passed closure

                    whenDone(self.recordSaved)

                    return
                }

                self.recordSaved = true
                
                // callback to the passed closure
                
                whenDone(self.recordSaved)
                
        // Mark: add a subscription to get a notification on a record change
        /*
                //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- self.publicDatabase.save -- closure -- setup subscription -- RecordId: Oscar-iphone")
                
                let locationSubscription = CKQuerySubscription(recordType: "Location", predicate: NSPredicate(format: "TRUEPREDICATE"), options: CKQuerySubscriptionOptions.firesOnRecordCreation)
                
                let locationNotificationInfo = CKNotificationInfo()
                
                locationNotificationInfo.shouldSendContentAvailable = true
                
                locationNotificationInfo.shouldBadge = false
                
                locationNotificationInfo.alertBody = "Oscar-ipad updated"
                
                locationSubscription.notificationInfo = locationNotificationInfo

                let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [locationSubscription], subscriptionIDsToDelete: [])
        
                operation.modifySubscriptionsCompletionBlock = {
                    
                    savedSubscriptions, deletedSubscriptionIDs, operationError in
                    if operationError != nil {
    
                        print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- error: \(String(describing: operationError))")

                    } else {

                        //print("-- CloudAdapter -- upload() -- self.publicDatabase.delete -- closure -- Subscribed")
                    }
                }
                
                self.publicDatabase.add(operation)
        */
        // MARK:- end
                
            }
        }
    }
    
}

