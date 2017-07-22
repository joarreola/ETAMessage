//
//  MapUpdate.swift
//  ETAMessages
//
//  Created by Oscar Arreola on 5/23/17.
//  Copyright © 2017 Oscar Arreola. All rights reserved.
//

import Foundation
import Messages
import MapKit
import CoreLocation
import CloudKit

/// Use to remove point annotations when request.

struct PointAnnotations {
    var pointAnnotation: MKPointAnnotation?
    
    init() {
        self.pointAnnotation = nil
    }
}

/// Update mapView centering and span.
/// Update mapVIew display overlay with coordinate and status information
///
/// addPin(Location, MKMapView, Bool)
/// centerView(Location, MKMapView)
/// centerView(Location, Location, MKMapView)
/// refreshMapView(Location, MKMapView)
/// refreshMapView(Location, Location, MKMapView, Bool)
/// refreshMapView(Location, MKMapView)
/// displayUpdate(UILabel)
/// displayUpdate(UILabel, String)
/// displayUpdate(UILabel, Location)
/// displayUpdate(UILabel, Location, String)
/// displayUpdate(UILabel, Location, String, String)
/// displayUpdate(UILabel, Location, Location)
/// displayUpdate(UILabel, Location, Location, String)
/// displayUpdate(UILabel, Location, Location, String, String)
/// displayUpdate(UILabel, Location, Location, Bool)

class MapUpdate {
    static var pointAnnotationStruct: PointAnnotations = PointAnnotations()
    private var latitude: CLLocationDegrees = 0.0
    private var longitude: CLLocationDegrees = 0.0
    private var locLatitude: CLLocationDegrees = 0.0
    private var locLongitude: CLLocationDegrees = 0.0
    private var remLatitude: CLLocationDegrees = 0.0
    private var remLongitude: CLLocationDegrees = 0.0


    /// Upload location packet to iCloud
    /// - Parameters:
    ///     - packet: location packet coordinates to note with a point annotation
    ///     - mapView: instance of MKMapView to add point annotation (red pin)
    ///     - remove: remove point annotation if true

    func addPin (packet: Location, mapView: MKMapView, remove: Bool) {
    
        let pointAnnotation: MKPointAnnotation
        
        pointAnnotation = MKPointAnnotation()
        
        
        pointAnnotation.coordinate = CLLocationCoordinate2D(latitude: packet.latitude!, longitude: packet.longitude!)
        
        if MapUpdate.pointAnnotationStruct.pointAnnotation != nil {
            
            let structlat = MapUpdate.pointAnnotationStruct.pointAnnotation!.coordinate.latitude
            let structlong = MapUpdate.pointAnnotationStruct.pointAnnotation!.coordinate.longitude
            
            if pointAnnotation.coordinate.latitude != structlat ||  pointAnnotation.coordinate.longitude != structlong {
                    
                mapView.removeAnnotation(MapUpdate.pointAnnotationStruct.pointAnnotation!)

            }
        }

        if remove {
            if MapUpdate.pointAnnotationStruct.pointAnnotation != nil {

                mapView.removeAnnotation(MapUpdate.pointAnnotationStruct.pointAnnotation!)
            }

        } else {

            if MapUpdate.pointAnnotationStruct.pointAnnotation != nil {
                
                mapView.removeAnnotation(MapUpdate.pointAnnotationStruct.pointAnnotation!)
            }
            mapView.addAnnotation(pointAnnotation)

        }
            
        MapUpdate.pointAnnotationStruct.pointAnnotation = pointAnnotation
    }

    /// Center mapView on localUser's location
    /// - Parameters:
    ///     - localpacket: location packet coordinates to center on
    ///     - mapView: instance of MKMapView to re-center mapView
    /// - Returns: new center coordinates

    func centerView (localpacket: Location, mapView: MKMapView) -> CLLocationCoordinate2D {
        
        var center: CLLocationCoordinate2D

        center = CLLocationCoordinate2D(latitude: localpacket.latitude!,
                                            longitude: localpacket.longitude!)
            
        mapView.setCenter(center, animated: true)
            
        return center
            
    }
    
    /// Center mapView between localUser and remoteUser locations.
    /// - Parameters:
    ///     - localpacket: localUser's location coordinates
    ///     - remotepacket: remoteUser's location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    /// - Returns:
    ///     - new center coordinates
    ///     - suggested delta value

    func centerView (localpacket: Location, remotePacket: Location, mapView: MKMapView) -> (CLLocationCoordinate2D, Double) {
    
        var centerLatitude: CLLocationDegrees
        var centerLongitude: CLLocationDegrees
        var center: CLLocationCoordinate2D
        let latDistTo: CLLocationDegrees
        let lngDistTo: CLLocationDegrees

        if remotePacket.latitude == 0.0 {

            center = CLLocationCoordinate2D(latitude: localpacket.latitude!,
                                            longitude: localpacket.longitude!)

            mapView.setCenter(center, animated: true)

            return (center, 0.1)

        }
        
        // for local and remote location pairs
        latDistTo = abs((localpacket.latitude?.distance(to: remotePacket.latitude!))!) / 2
        lngDistTo = abs((localpacket.longitude?.distance(to: remotePacket.longitude!))!) / 2

        centerLatitude = (Double(localpacket.latitude!) > Double(remotePacket.latitude!)) ?
            (remotePacket.latitude! + latDistTo) :
            (localpacket.latitude! + latDistTo)
        

        // negative longitudes
        centerLongitude = (Double(localpacket.longitude!) > Double(remotePacket.longitude!)) ?
            (remotePacket.longitude! + lngDistTo) :
            (localpacket.longitude! + lngDistTo)

        center = CLLocationCoordinate2D(latitude: centerLatitude,
                                            longitude: centerLongitude)
        
        mapView.setCenter(center, animated: true)
    
        // use the lager of latDistTo and lngDistTo as a suggested dist value
        let dist = (latDistTo < lngDistTo) ? lngDistTo : latDistTo

        return (center, dist)
        
    }
    
    /// Refresh mapView to be centered on a single coordinate and a span of 0.1
    /// - Parameters:
    ///     - packet: location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView

    func refreshMapView(packet: Location, mapView: MKMapView) {
        
        let delta: Float = 0.1
        let center: CLLocationCoordinate2D
        
        // center mapView on single, local coordinates
        center = self.centerView(localpacket: packet, mapView: mapView)
        
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                      longitudeDelta: CLLocationDegrees(delta))
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    func refreshMapView(packet: Location, mapView: MKMapView, delta: Double) {
        
        //let delta: Float = 0.1
        let center: CLLocationCoordinate2D
        
        // center mapView on single, local coordinates
        center = self.centerView(localpacket: packet, mapView: mapView)
        
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                      longitudeDelta: CLLocationDegrees(delta))
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        
    }
    
    /// Refresh mapView to be centered between two coordinate and a span set to
    /// contain both coordinate points in the centered mapView.
    /// - Parameters:
    ///     - localpacket: localUser's location coordinates
    ///     - remotepacket: remoteUser's location coordinates
    ///     - mapView: instance of MKMapView to re-center mapView
    ///     - eta: EtaAdapter instance with eta and distance properties
    /*
    func refreshMapView(localPacket: Location, remotePacket: Location, mapView: MKMapView, eta: Bool) {
        //print("-- MapUpdate -- refreshMapView: refresh mapView for local and remote coordinates")

        let delta: Float
        let center: CLLocationCoordinate2D
        let dist: Double
        
        // center coordinates between devices or single local coordinates
        (center, dist) = self.centerView(localpacket: localPacket, remotePacket: remotePacket, mapView: mapView)

        // compute delta based on distance
        if EtaAdapter.distance == nil || remotePacket.latitude == 0.0 {

            //delta = 0.1
            delta = Float(dist * 3)

        } else {
            // compute a delta to reset the span.
            let distance = EtaAdapter.distance!

            delta = Float(distance * 0.0000015)

        }

        // span
        let span: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: CLLocationDegrees(delta),
                                                      longitudeDelta: CLLocationDegrees(delta))

        let region = MKCoordinateRegion(center: center, span: span)

        mapView.setRegion(region, animated: true)

    }
    */
    /// Clear display with local location coordinates
    /// - Parameters:
    ///     - display: UILabel instance display

    func displayUpdate(display: UILabel) {
        
        display.text = ""

    }
    
    /// Update display with a single string message
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - string: message to display

    func displayUpdate(display: UILabel, string: String) {
        
        display.text = ""
        display.text = "- \(string)"
        
    }
    
    /// Replace nil with 0.0
    /// - Parameters
    ///     - packet: location coordinates to display
    /// - Returns
    ///     - latitude: value or 0.0
    ///     - longitude: value or 0.0

    func packetCleanup(packet: Location) {

        self.latitude  = Double(packet.latitude ?? 0.0)
        self.longitude = Double(packet.longitude ?? 0.0)
        
    }

    /// Replace nil with 0.0
    /// - Parameters
    ///     - packet: location coordinates to display
    /// - Returns
    ///     - latitude: value or 0.0
    ///     - longitude: value or 0.0

    func packetCleanup(localPacket: Location, remotePacket: Location) {
        
        self.locLatitude  = Double(localPacket.latitude ?? 0.0)
        self.locLongitude = Double(localPacket.longitude ?? 0.0)
        self.remLatitude  = Double(remotePacket.latitude ?? 0.0)
        self.remLongitude = Double(remotePacket.longitude ?? 0.0)

    }

    /// Update display with local coordinates
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - packet: location coordinates to display

    func displayUpdate(display: UILabel, packet: Location) {
        
        // cleanup packet
        packetCleanup(packet: packet)

        display.text = ""
        display.text = "local:\t( \(self.latitude),\n\t\t\(self.longitude) )"
        
    }

    /// Update display with local coordinates and a string message
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - packet: location coordinates to display
    ///     - string: message to display

    func displayUpdate(display: UILabel, packet: Location, string: String) {

        // cleanup packet
        packetCleanup(packet: packet)
        
        display.text = ""
        display.text = "local:\t( \(self.latitude),\n\t\t\(self.longitude) )\n" + "- \(string)"
        
    }
    
    /// Update display with local coordinates and two string messages
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - packet: location coordinates to display
    ///     - string: message to display
    ///     - secondString: a second message to display

    func displayUpdate(display: UILabel, packet: Location, string: String, secondString: String) {
        
        // cleanup packet
        packetCleanup(packet: packet)

        display.text = ""
        display.text =  "local:\t( \(self.latitude),\n\t\t\(self.longitude) )\n" +
                        "- \(string)\n" +
                        "- \(secondString)"
        
    }
    
    /// Update display with a local coordinates and remote coordinates
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - localPacket: local location coordinates to display
    ///     - remotePacket: remote location coordinates to display

    func displayUpdate(display: UILabel, localPacket: Location, remotePacket: Location) {
        
        // cleanup packets
        packetCleanup(localPacket: localPacket, remotePacket: remotePacket)

        display.text = ""
        display.text =  "local:\t( \(self.locLatitude),\n\t\t\(self.locLongitude) )\n" +
                        "remote:\t( \(self.remLatitude),\n\t\t\(self.remLongitude) )"
        
    }

    /// Update display with a local and remote coordinates and a string message
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - localPacket: local location coordinates to display
    ///     - remotePacket: remote location coordinates to display
    ///     - string: message to display

    func displayUpdate(display: UILabel, localPacket: Location, remotePacket: Location,
                       string: String) {
        
        // cleanup packets
        packetCleanup(localPacket: localPacket, remotePacket: remotePacket)

        display.text = ""
        display.text =  "local:\t( \(self.locLatitude),\n\t\t\(locLongitude) )\n" +
                        "remote:\t( \(self.remLatitude),\n\t\t\(self.remLongitude) )\n" +
                        "- \(string)"

    }
    
    /// Update display with a local and remote coordinates and two string messages
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - localPacket: local location coordinates to display
    ///     - remotePacket: remote location coordinates to display
    ///     - string: message to display
    ///     - secondString: a second message to display

    func displayUpdate(display: UILabel, localPacket: Location, remotePacket: Location,
                       string: String, secondString: String) {
        
        // cleanup packets
        packetCleanup(localPacket: localPacket, remotePacket: remotePacket)

        display.text = ""
        display.text =  "local:\t( \(self.locLatitude),\n\t\t\(self.locLongitude) )\n" +
                        "remote:\t( \(self.remLatitude),\n\t\t\(self.remLongitude) )\n" +
                        "- \(string)\n" +
                        "- \(secondString)"
        
    }
    
    /// Update display with a local and remote coordinates and two string messages
    /// - Parameters:
    ///     - display: UILabel instance display
    ///     - localPacket: local location coordinates to display
    ///     - remotePacket: remote location coordinates to display
    ///     - eta: EtaAdapter instance with eta and distance properties
    /*
    func displayUpdate(display: UILabel, localPacket: Location, remotePacket: Location, eta: Bool) {
        
        // cleanup packets
        packetCleanup(localPacket: localPacket, remotePacket: remotePacket)

        let etaString: String
        let distanceString: String

        if EtaAdapter.distance == nil {
            distanceString = "nil"
        } else {
            distanceString = String(describing: EtaAdapter.distance!)
        }
        
        if EtaAdapter.eta == nil {
            etaString = "nil"
        } else {
            etaString = String(describing: EtaAdapter.eta!)
        }
        
        display.text = ""
        
        display.text =  "local:  \t( \(self.locLatitude),\n  \t\t\(self.locLongitude) )\n" +
                        "remote:  \t( \(self.remLatitude),\n  \t\t\(self.remLongitude) )\n" +
                        "eta:  \t\(etaString) sec\n" +
                        "distance: \(distanceString) ft"
    
    }
    */
    /*
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = UIColor.blue
        return renderer
    }
    */
}
