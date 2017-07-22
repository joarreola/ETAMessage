//
//  Eta.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/31/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import AVFoundation

/// Adapter to ETA server for eta and distance data
///
/// eta { get set }
/// distance { get set }
/// getEtaDistance(Location, Location)

struct ETAIndicator {
    var etaProgress: UIProgressView? = nil
    var progressLabel: UILabel? = nil
}

class EtaAdapter: UIViewController {
    static var eta: TimeInterval? = nil
    static var distance: Double? = nil
    private var mapUdate: MapUpdate = MapUpdate()
    static var previousDistance: TimeInterval? = nil

    @IBOutlet weak var etaProgress: UIProgressView!
    @IBOutlet weak var progressLabel: UILabel!
    

    static var etaIndicator = ETAIndicator()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //print("-- EtaAdapter -- viewDidLoad() -----------------------------")
        
        self.etaProgress.transform = self.etaProgress.transform.scaledBy(x: 1, y: 7)
        self.etaProgress.setProgress(Float(0.0), animated: true)
        
        // to hold progress and label
        EtaAdapter.etaIndicator.etaProgress = self.etaProgress
        EtaAdapter.etaIndicator.progressLabel = self.progressLabel
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- EtaAdapter -- viewWillAppear -----------------------------------")
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- EtaAdapter -- viewDidAppear ------------------------------------")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- EtaAdapter -- viewWillDisappear --------------------------------")

    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //print("-- EtaAdapter -- viewDidDisappear ---------------------------------")
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        //print("-- EtaAdapter -- didReceiveMemoryWarning --------------------------")
    }
    
    //var player: AVAudioPlayer?
    /*
    init() {
        EtaAdapter.eta = nil
        EtaAdapter.distance = nil
        self.mapUdate = MapUpdate()

    }
    */

    func setEta(eta: TimeInterval) {
        EtaAdapter.eta = eta
    }
    
    func getEta() -> TimeInterval? {
        return EtaAdapter.eta
    }
    
    func setDistance(distance: Double) {
        EtaAdapter.distance = distance
    }
    
    func getDistance() -> Double? {
        return EtaAdapter.distance
    }
    
    /// Makes mkDirections.calculate() call for eta and distance data
    /// - Parameters:
    ///     - localPacket: location coordinates for local user
    ///     - remotePacket: location coordintates for remote user
    ///     - mapView: refresh mapView
    ///     - etaAdapter: update eta and distance data
    ///     - display: update display content

    func getEtaDistance(localPacket: Location, remotePacket: Location, mapView: MKMapView, display: UILabel,  etaOriginal: TimeInterval) {

        _getEtaDistance (localPacket: localPacket, remotePacket: remotePacket, mapView: mapView, display: display, etaOriginal: etaOriginal)
    }

    func getEtaDistance (localPacket: Location, remotePacket: Location, mapView: MKMapView, display: UILabel) {
        // for called by checkRemote() in GPSLocation

        let etaOriginal: TimeInterval = 0.0

        _getEtaDistance (localPacket: localPacket, remotePacket: remotePacket, mapView: mapView, display: display, etaOriginal: etaOriginal)
        
    }

    func _getEtaDistance (localPacket: Location, remotePacket: Location, mapView: MKMapView, display: UILabel, etaOriginal: TimeInterval?) {

        let mkDirReq: MKDirectionsRequest = MKDirectionsRequest()
        
        mkDirReq.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: localPacket.latitude!, longitude: localPacket.longitude!), addressDictionary: nil))

        mkDirReq.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: remotePacket.latitude!, longitude: remotePacket.longitude!), addressDictionary: nil))
        
        mkDirReq.requestsAlternateRoutes = false
        mkDirReq.transportType = .automobile
        //mkDirReq.transportType = .walking
        
        let mkDirections = MKDirections(request: mkDirReq)
        
        mkDirections.calculate { [ unowned self ] (response, error) in
            
            if error != nil {
                print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- error -- Error: \(String(describing: error))")
                
                // UI updates on main thread
                DispatchQueue.main.async { [weak self ] in
                    
                    if self != nil {

                        self?.mapUdate.displayUpdate(display: display, localPacket: localPacket, remotePacket: remotePacket, string: "eta not available", secondString: "distance not available")
                    }
                }
                
                EtaAdapter.eta = nil
                EtaAdapter.distance = nil

                return
            }

            // can't get self.eta nor self.distance out of the closure on 1st poll
            guard let unwrappedResponse = response else {
                
                print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- unwrappedResponse -- Error: \(String(describing: error))")
                
                EtaAdapter.eta = nil
                EtaAdapter.distance = nil
                
                return
            }
            
            for route in unwrappedResponse.routes {
                //mapView.add(route.polyline)
                //mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)

                self.setEta(eta: route.expectedTravelTime)
                self.setDistance(distance: route.distance * 3.2808)

                for _ in route.steps {
                    //print(step.instructions)
                }

                if EtaAdapter.previousDistance == nil || Double(EtaAdapter.distance!) < Double(EtaAdapter.previousDistance!) {

                    EtaAdapter.previousDistance = EtaAdapter.distance

                } else if Double(EtaAdapter.distance!) > Double(EtaAdapter.previousDistance!) {
                    // for simulation: don't update mapView if got a greater DISTANCE

                    return
                }
            }
            
            // UI updates on main thread
            DispatchQueue.main.async { [weak self ] in
                
                if self != nil {
                    // add pin and refresh mapView
                    //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- DispatchQueue.main.async -- closure")
                    /*
                    self?.mapUdate.addPin(packet: remotePacket, mapView: mapView, remove: false)
                    
                    self?.mapUdate.refreshMapView(localPacket: localPacket, remotePacket: remotePacket, mapView: mapView, eta: true)
                    
                    self?.mapUdate.displayUpdate(display: display, localPacket: localPacket, remotePacket: remotePacket, eta: true)
                    */
                    //print("-- EtaAdapter -- getEtaDistance() -- mkDirections.calculate() -- closure -- DispatchQueue.main.async -- closure -- etaOriginal: \(String(describing: etaOriginal))")

                    if etaOriginal != 0.0 {
                        
                        EtaAdapter.etaIndicator.etaProgress?.setProgress(Float(EtaAdapter.eta!) / Float(etaOriginal!), animated: true)

                        let etaMinutes = Int(EtaAdapter.eta! / 60)
                        if etaMinutes != 0 {
                            EtaAdapter.etaIndicator.progressLabel?.text = "\(etaMinutes) min"
                        } else {
                            EtaAdapter.etaIndicator.progressLabel?.text = ""
                            EtaAdapter.etaIndicator.etaProgress?.setProgress(Float(0.0), animated: true)
                            
                            UploadingManager.enabledUploading = false
                            
                        }

                        /*
                        self?.player = self?.loadSound(name: "hornSound")
                        
                        if self?.player != nil {

                            self?.player?.play()
                        }
                        */
                    }
                }
            }
        }
    }
    /*
    func loadSound(name: String)  -> AVAudioPlayer? {
        let bundle = Bundle.main

        let optionalPath = bundle.path(forResource: name, ofType: "m4a")
        
        if let path = optionalPath {

            let url = URL(fileURLWithPath: path)

            let optionalPlayer = try? AVAudioPlayer(contentsOf: url)
            
            if let player = optionalPlayer {

                player.prepareToPlay()
                
                print("\(name) loaded.")
                
                return player
            }
            else {
                print("Could not load \(name).")
                
                return nil
            }
        }
        else {
            print("Could not create path")
            
            return nil
        }
    }
    */
}
