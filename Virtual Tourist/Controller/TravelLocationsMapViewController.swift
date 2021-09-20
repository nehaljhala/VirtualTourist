//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Nehal Jhala on 8/19/21.
//

import UIKit
import MapKit
import CoreData
import CoreLocation

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var geoCoder = CLGeocoder()
    var onTheCallDatabase = OnTheCallDatabase()
    let client = Client()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.isUserInteractionEnabled = true
        mapView.isScrollEnabled = true
        mapView.isZoomEnabled = true
        mapView.delegate = self
        pinchToZoom()
        locationManager.delegate = self
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longTap))
        mapView.addGestureRecognizer(longTapGesture)
        showAnnotations()
    }
    
    @objc func longTap(sender: UIGestureRecognizer)  {
        print("long tap")
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
            let albumLoc = self.onTheCallDatabase.saveLocInfo(locationOnMap.latitude, locationOnMap.longitude)
            client.downloadImagesFromAPI(locationOnMap.latitude, locationOnMap.longitude, 1, albumLoc)
        }
    }
    
    //Pinch Gesture for Mapview:
    func pinchToZoom(){
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        mapView.addGestureRecognizer(pinchGesture)
    }
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer){
        if gesture.state == .changed{
            let scale = gesture.scale
        }
    }
    
    func addAnnotation(location: CLLocationCoordinate2D) {
        var pins = [MKPointAnnotation]()
        let annotation = MKPointAnnotation()
        annotation.coordinate = location
        annotation.title = "View Photos"
        self.mapView.addAnnotation(annotation)
        pins.append(annotation)
    }
    
    func showAnnotations(){
        var oldPins = [MKPointAnnotation]()
        let pinArray = onTheCallDatabase.fetchLocDetails()
        if pinArray.count >= 1 {
            for pin in pinArray {
                let coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lon)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotation.title = "View Photos"
                oldPins.append(annotation)
            }
            self.mapView.addAnnotations(oldPins)
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKPointAnnotation else { print("no mkpointannotaions"); return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView!.pinTintColor = UIColor.red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let lat = view.annotation!.coordinate.latitude
            let lon = view.annotation!.coordinate.longitude
            getImagesFromDatabase(lat,lon)
        }
    }
    
    func getImagesFromDatabase(_ lat:CLLocationDegrees,_ lon:CLLocationDegrees){
        let albumLoc = onTheCallDatabase.fetchAlbumLocation(lat, lon)
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: "photoView") as! PhotoAlbumViewController
        nextViewController.modalPresentationStyle = .fullScreen
        nextViewController.albumLocation = albumLoc
        nextViewController.lat = lat
        nextViewController.lon = lon
        self.present(nextViewController, animated:true, completion:nil)
        NotificationCenter.default.post(name: .didFinishSave, object: nil)
        return
    }
    
}




