//
//  EtaNotifications.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 6/5/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UserNotifications
import UserNotifications

class ETANotifications {
    
    weak var delegate: UNUserNotificationCenter?

    // configure
    let content = UNMutableNotificationContent()
    let center = UNUserNotificationCenter.current()
    
    init() {
    }

    func configureContent(milePost: String) {
        //print("-- EtaNotifications -- configureContent()")
        
        // 1- Configure the content.
        self.content.title = NSString.localizedUserNotificationString(forKey: "ETAMessages", arguments: nil)
        self.content.body = NSString.localizedUserNotificationString(forKey: milePost, arguments: nil)
        
        self.content.sound = UNNotificationSound.default()
    
    }
    
    func scheduleNotification() {
        //print("-- EtaNotifications -- scheduleNotification()")
        
        // Deliver the notification in 1 second.

        // 2- configure the trigger. can't be <60sec if repeating
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        //print("-- EtaNotifications -- scheduleNotification() -- UNTimeIntervalNotificationTrigger()")

        // 3- Create the request object.
        let request = UNNotificationRequest(identifier: "ETAMessages", content: self.content, trigger: trigger)
        //print("-- EtaNotifications -- scheduleNotification() -- UNNotificationRequest()")
        
        // 4- Schedule the notification.
        //print("-- EtaNotifications -- scheduleNotification -- center.add(request)")

        center.add(request) { (error : Error?) in
            if error != nil {
                print("-- EtaNotifications -- scheduleNotification -- center.add -- closure -- error: \(String(describing: error?.localizedDescription))")
            } else {
                //print("-- EtaNotifications -- scheduleNotification -- center.add -- closure -- Succeeded")
            }
        }
    }

    func requestAuthorization() {
        //print("-- EtaNotifications -- requestAuthorization()")
        
        // requestAuthorization
        self.center.requestAuthorization(options: [.alert, .sound]) {
            // Enable or disable features based on authorization.
            
            (granted, error) in
            
            if error != nil {
                print("-- EtaNotifications -- requestAuthorization() -- self.center.requestAuthorization() -- closure -- error: \(String(describing: error))")
                
                return
            }
            
            if granted {

                //print("-- EtaNotifications -- requestAuthorization() -- self.center.requestAuthorization() -- closure -- granted: \(granted)")
            
                let generalCategory = UNNotificationCategory(identifier: "OneSecond",
                                                         actions: [],
                                                         intentIdentifiers: [],
                                                         options: .customDismissAction)
            
                self.center.setNotificationCategories([generalCategory])
            }
            
        }
    }

    func all() {
         //print("-- EtaNotifications -- all()")
        
        // configure
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Hello!", arguments: nil)
        content.body = NSString.localizedUserNotificationString(forKey: "Hello_message_body", arguments: nil)
        content.sound = UNNotificationSound.default()
        
        // Deliver the notification in five seconds.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "FiveSecond", content: content, trigger: trigger)
        
        // Schedule the notification.
        let center = UNUserNotificationCenter.current()
        center.add(request) { (error : Error?) in
            if let theError = error {
                print(theError.localizedDescription)
            }
        }
    }
    
    func registerNotification() {
        // Register
        //print("-- EtaNotifications -- registerNotification()")
        
        let generalCategory = UNNotificationCategory(identifier: "GENERAL",
                                                 actions: [],
                                                 intentIdentifiers: [],
                                                 options: .customDismissAction)
    
        // Register the category.
        center.setNotificationCategories([generalCategory])
    }

}
