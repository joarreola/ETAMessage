//
//  LocalNotificationDelegate.swift
//  ETAMessages
//
//  Created by taiyo on 6/19/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit
import UserNotifications

class LocalNotificationDelegate: UNUserNotificationCenter,  UNUserNotificationCenterDelegate {


    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        //print("-- LocalNotificationDelegate -- userNotificationCenter()")

        // notification
        //print("-- LocalNotificationDelegate -- userNotificationCenter() -- notification.request.identifier: \(notification.request.identifier)")
        
        // Play a sound.
        //completionHandler(UNNotificationPresentationOptions.sound)
        completionHandler(UNNotificationPresentationOptions.alert)
    }

}
