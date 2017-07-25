//
//  ViewController.swift
//  ETAMessage
//
//  Created by taiyo on 7/6/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import MapKit


class ViewController: UIViewController, MKMapViewDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    //var locationManager = CLLocationManager()
    var mapUpdate = MapUpdate()
    let localUser  = Users(name: "Oscar-iphone")
    var uploading = UploadingManager(name: "Oscar-iphone")
    var gpsLocation = GPSLocationAdapter()
    var locationManager = CLLocationManager()

    static var UserName = "Oscar-iphone"
    var locPacketUpdated: Bool = false
    static var locationManagerEnabled: Bool = true
    var localUUID: UUID = UUID(uuidString: "49B5E9E4-967F-4CD4-BCD7-B3439715EE58")!
    var remoteUUID: UUID = UUID(uuidString: "49B5E9E4-967F-4CD4-BCD7-B3439715EE58")!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        self.mapView.showsUserLocation = true
        self.mapView.delegate = self
        
        // check userDefaults
        let mySharedDefaults = UserDefaults.init(suiteName: "group.edu.ucsc.ETAMessages.SharedContainer")
        let uuidObject = mySharedDefaults?.string(forKey: "remoteUUID")
        print("-- ViewController -- viewDidLoad -- uuidObject: \(String(describing: uuidObject))")
        
        self.locationManager.delegate = self as? CLLocationManagerDelegate
        //if !CLLocationManager.locationServicesEnabled() {
        if true {
            // location services is disabled, alert user
            /*
             //let servicesDisabledAlert = UIAlertView(title: "Alert", message: "Location service is disable. Please enable to access your current location.", delegate: nil, cancelButtonTitle: "OK", otherButtonTitles: "")
             */
            
            print("-- ViewController -- pre alert\n")
            let alert = UIAlertController(title: "Alert", message: "Location service is disable. Please enable to access your current location.", preferredStyle: UIAlertControllerStyle.alert)
            let defaultAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) {
                (action) in
                print("-- ViewController -- UIAlertAction() -- closure -- action: \(action)\n")
            }
            alert.addAction(defaultAction)
            self.present(alert, animated: true)
            print("-- ViewController -- post alert\n")
            
            
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
            print("-- AppDelegate -- getLocation() -- call: self.locationManager.startUpdatingLocation()\n")
            self.locationManager.startUpdatingLocation()
            self.locationManager.startMonitoringSignificantLocationChanges()
        }

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

