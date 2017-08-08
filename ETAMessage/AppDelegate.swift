//
//  AppDelegate.swift
//  ETAMessage
//
//  Created by taiyo on 7/6/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import UIKit
import CoreData
//import CoreLocation
import UserNotifications

@UIApplicationMain
//class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate, UIAlertViewDelegate, UNUserNotificationCenterDelegate {
class AppDelegate: UIResponder, UIApplicationDelegate, UIAlertViewDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    //var locationManager = CLLocationManager()
    //var mapUpdate = MapUpdate()
    let localUser  = Users(name: "Oscar-iphone")
    var gpsLocation = GPSLocationAdapter()
    
    static var UserName = "Oscar-iphone"
    var locPacketUpdated: Bool = false
    static var locationManagerEnabled: Bool = true
    var requestAlwaysAuthorization: Bool = true

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        print("-- AppDelegate -- application(didFinishLaunchingWithOptions) -----------------\n")
        
        let backgroundRefreshStatus: UIBackgroundRefreshStatus = UIBackgroundRefreshStatus(rawValue: application.backgroundRefreshStatus.rawValue)!

        print("-- AppDelegate -- application.backgroundRefreshStatus: \(backgroundRefreshStatus)\n")
        
        let state = application.applicationState

        print("-- AppDelegate -- application.applicationState: \(state)\n")
        
    // MARK: REGISTER FOR PUSH NOTIFICATIONS

        // Configure the user interactions first.
        //self.configureUserInteractions()
        
        // Register with APNs
        print("-- AppDelegate -- application(didFinishLaunchingWithOptions) -- REGISTER FOR PUSH NOTIFICATIONS\n")
        //notficationSettings = UIUserNotificationSettings(types: UIUserNotificationType, categories: Set<UIUserNotificationCategory>?)
        //let notficationSettings = UNNotificationSettings(types: UIUserNotificationTypeAlert, categories: nil)
        //let notficationSettings = UNNotificationSettings(type: , categories: nil)
        

        application.registerForRemoteNotifications()
        
        
        print(application.currentUserNotificationSettings!)

    // MARk:-

        return true
    }

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        print("-- AppDelegate -- application(willFinishLaunchingWithOptions)\n")

        return true
    }

    // Handle remote notification registration.
    @nonobjc func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data){
        print("-- AppDelegate -- application(didRegisterForRemoteNotificationsWithDeviceToken)\n")

        // Forward the token to your provider, using a custom method.
        //self.enableRemoteNotificationFeatures()
        //self.forwardTokenToServer(token: deviceToken)
    }
    
    @nonobjc func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("-- AppDelegate -- application(didFailToRegisterForRemoteNotificationsWithError)")
        
        // The token is not currently available.
        print("Remote notification support is unavailable due to error: \(error.localizedDescription)\n")
        //self.disableRemoteNotificationFeatures()
    }

    @nonobjc func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Configure the user interactions first.
        print("-- AppDelegate -- applicationDidFinishLaunching(aNotification) -- aNotification: \(aNotification)\n")
        
        
        //self.configureUserInteractions()
        
        //UIApplication.shared.registerForRemoteNotifications(matching: [.alert, .sound])
        /*
        // Register with APNs
        print("-- AppDelegate -- applicationDidFinishLaunching() -- registerForRemoteNotifications")
        UIApplication.shared.registerForRemoteNotifications()
        */
    }


    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        print("-- AppDelegate -- application(handleEventsForBackgroundURLSession) -- identifier: \(identifier) --------------\n")

        //code
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

        print("-- AppDelegate -- application(didReceiveRemoteNotification) -- userInfo: \(userInfo)--------------\n")
        
        /*
        var message: NSString = ""
        */
        let alertCk: AnyObject? = userInfo["ck"] as AnyObject
        //print(alertCk!["qry"])
        let alertQry: AnyObject? = alertCk?["qry"] as AnyObject
        //print(alertQry ?? "None")
        let alertRid: AnyObject? = alertQry?["rid"] as AnyObject
        print(alertRid ?? "None")
        let rid = String(describing: alertRid!)
        

        //message = alertCk?["alert"] as! NSString

        // get remoteUUID from userDefaults
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        let uuidObject = mySharedDefaults?.string(forKey: "remoteUUID")
        self.localUser.name = String(describing: uuidObject!)

        if((alertCk) != nil && rid == self.localUser.name) {

            // fetch location record
            print("-- AppDelegate -- application(didReceiveRemoteNotification) -- fetch: \(self.localUser.name)\n")

            self.gpsLocation.fetchFromIcloud(user: self.localUser) {
            
                (location: Location) in

                if location.latitude != nil {

                    // note record and location info in alert
                    print("-- AppDelegate -- application(didReceiveRemoteNotification) -- Location: \(String(describing: location.latitude!)), \(String(describing: location.longitude!))\n")
                    
                    // Visible only when ETAMessage "C-app" is in foreground.
                    // Blocks on OK button.
                    DispatchQueue.main.async { [weak self ] in
                        
                        if self != nil {
                            /*
                            let alert = UIAlertView()
                            alert.title = "Location Record: \(String(describing: self?.localUser.name))"
                            alert.message = "\(String(describing: location.latitude!)), \(String(describing: location.longitude!))"
                            //alert.addButton(withTitle: "OK")
                            alert.show()
                            */
                            
                            // from locationManager
                            let alert: UIAlertControllerStyle = UIAlertControllerStyle.alert
                            let locationAlert = UIAlertController(title: "Remote Location",
                                                               message: "\(String(describing: location.latitude!)), \(String(describing: location.longitude!))",
                                                               preferredStyle: alert)
                            //errorAlert.show(UIViewController(), sender: manager)
                            locationAlert.show(UIViewController(), sender: application)
                        }
                    }
                    
                    // also note in Userdefaults
                    mySharedDefaults?.set(location.latitude!, forKey: "latitude")
                    mySharedDefaults?.set(location.longitude!, forKey: "longitude")
                    mySharedDefaults?.synchronize()
                }
            }
        }
        completionHandler(UIBackgroundFetchResult.newData)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        print("-- AppDelegate -- applicationWillResignActive() --------------------------")
        /*
        self.locationManager.delegate = self
        print("-- AppDelegate -- applicationWillResignActive() -- stopUpdatingLocation --------------\n")
        self.locationManager.stopUpdatingLocation()
        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.pausesLocationUpdatesAutomatically = false
        //self.locationManager.activityType = CLActivityType.automotiveNavigation
        self.locationManager.activityType = CLActivityType.fitness
        print("-- AppDelegate -- applicationWillResignActive() -- startUpdatingLocation -----\n")

        self.locationManager.startUpdatingLocation()
        //self.locationManager.startMonitoringSignificantLocationChanges()
        */
        
        // check userDefaults
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        let uuidObject = mySharedDefaults?.string(forKey: "remoteUUID")
        print("-- AppDelegate -- applicationWillResignActive -- uuidObject: \(String(describing: uuidObject))\n")
        self.localUser.name = String(describing: uuidObject!)
        
        // subscribe here
        print("-- AppDelegate -- applicationWillResignActive() -- subscribe: \(String(describing: uuidObject!))\n")
        let cloud = CloudAdapter()
        cloud.subscribe(userUUID: String(describing: uuidObject!))
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("-- AppDelegate -- applicationDidEnterBackground() ----------------------\n")
        
        /*
        print("-- AppDelegate -- applicationDidEnterBackground() -- startUpdating,startMonitoring")

        print("-- AppDelegate -- applicationDidEnterBackground() -- call getLocation()...")
        self.getLocation()
        
        print("-- AppDelegate -- applicationDidEnterBackground() -- startUpdating,startMonitoring")
        self.locationManager.startUpdatingLocation()
        self.locationManager.startMonitoringSignificantLocationChanges()
        */
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("-- AppDelegate -- applicationWillEnterForeground() ----------------------------------\n")
        
        /*
        //print("-- AppDelegate -- applicationWillEnterForeground() -- stopMonitoring,startUpdating")

        self.locationManager.stopMonitoringSignificantLocationChanges()
        self.locationManager.startUpdatingLocation()
        */
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("-- AppDelegate -- applicationDidBecomeActive() ---------------------------------------")

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        print("-- AppDelegate -- applicationWillTerminate() -----------------------------------------\n")
        self.saveContext()
    }


    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        print("-- AppDelegate -- persistentContainer --------------------------------------------------------------")
        let container = NSPersistentContainer(name: "ETAMessage")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print("-- AppDelegate -- persistentContainer -- container.loadPersistentStores -- closure -------------")

            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        print("-- AppDelegate -- persistentContainer -- after closure -------------------------------")
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        print("-- AppDelegate -- saveContext() ------------------------------------------------------")
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }


    /**
     *
     * Called by the CLLocation Framework on GPS location changes
     *
     */
/*
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        // locationManager(:didUpdateLocations) guarantees that locations will not
        // be empty
        let location = locations.last!
        let lmPacket = Location(userName: "", location: location)

        // refresh mapView from locationManager just once
        if !locPacketUpdated
        {
            
            self.localUser.location = lmPacket
            
            //self.mapUpdate.refreshMapView(packet: lmPacket, mapView: mapView)
            
            //mapUpdate.displayUpdate(display: display, string: "locationManager...")
            
            locPacketUpdated = true
            
        }

         // abort if disabled
         if !AppDelegate.locationManagerEnabled {
         
         return
         }

        // nothing to update if same location
        if lmPacket.latitude == localUser.location.latitude &&
            lmPacket.longitude == localUser.location.longitude
        {
            
            return
        }

        // A new location: update User's Location object
        print("-- AppDelegate -- locationManager -- location: '\(location)'\n")
        
        //gpsLocation.updateUserCoordinates(localUser: localUser, packet: lmPacket)
        self.localUser.location = lmPacket
        
        //if (UploadingManager.enabledUploading) {
        // refresh mapView if enabledUploading
        /*
         // don't refresh MapView centered on localUser if polling enabled
         if !PollManager.enabledPolling {
         //print("-- locationManager -- refresh mapView for localUser")
         
         self.mapUpdate.refreshMapView(packet: localUser.location, mapView: mapView)
         }
         */
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        let uuidObject = mySharedDefaults?.string(forKey: "remoteUUID")
        print("-- AppDelegate -- locationManager -- uuidObject: \(String(describing: uuidObject))\n")
        
        localUser.name = String(describing: uuidObject!)

        print("-- AppDelegate -- locationManager -- call: self.gpsLocation.uploadToIcloud(user: localUser.name)\n")
        self.gpsLocation.uploadToIcloud(user: localUser) {
            
            (result: Bool) in
            
            print("-- AppDelegate -- locationManager -- self.gpsLocation.uploadToIcloud() -- closure -- result: \(result)\n")
            
            //self.gpsLocation.handleUploadResult(result, display: self.display, localUser: self.localUser, remoteUser: self.remoteUser, mapView: self.mapView, pollManager: self.pollManager)
        }
 
        //}
    }


    @nonobjc func locationManager(manager: CLLocationManager!,
                                  didFailWithError error: NSError!) {
        
        print("-- AppDelegate -- locationManager -- didFailWithError: \(error.description)\n")
        let alert: UIAlertControllerStyle = UIAlertControllerStyle.alert
        let errorAlert = UIAlertController(title: "Error",
                                           message: "Failed to Get Your Location",
                                           preferredStyle: alert)
        errorAlert.show(UIViewController(), sender: manager)
        
    }
*/
    
/*
    func getLocation() {
        print("-- AppDelegate -- getLocation() -------------------------------------------\n")

        self.locationManager = CLLocationManager()
        self.locationManager.delegate = self
        if self.locationManager.responds(to: #selector(getter: self.requestAlwaysAuthorization)) {
            self.locationManager.requestAlwaysAuthorization()
        }
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        //self.locationManager.activityType = CLActivityType.fitness
        self.locationManager.activityType = CLActivityType.automotiveNavigation
        /*
        if !CLLocationManager.locationServicesEnabled() {
            // location services is disabled, alert user
            /*
            //let servicesDisabledAlert = UIAlertView(title: "Alert", message: "Location service is disable. Please enable to access your current location.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
            */
            
            print("-- AppDelegate -- getLocation() - pre alert\n")
            let alert = UIAlertController(title: "Alert", message: "Location service is disable. Please enable to access your current location.", preferredStyle: UIAlertControllerStyle.alert)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (action) in
                print("-- AppDelegate -- getLocation() -- UIAlertAction() -- closure -- action: \(action)\n")
            }
            alert.addAction(defaultAction)
            let view = ViewController()
            view.present(alert, animated: true, completion:nil)
            print("-- AppDelegate -- getLocation() - post alert\n")

            
            /*
            UIAlertController* alert: UIAlertController = [UIAlertController alertControllerWithTitle:@"My Alert"
                message:@"This is an alert."
                preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            */
        }
        else {
        */
            print("-- AppDelegate -- getLocation() -- call: self.locationManager.startUpdatingLocation()\n")
            self.locationManager.startUpdatingLocation()
            self.locationManager.startMonitoringSignificantLocationChanges()
        //}
    }
 */

/*
    func configureUserInteractions() {
    
    }
*/

}

