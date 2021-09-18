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
    // let coordinate = CLLocationCoordinate2D()
    //var userMapLocation = CLLocationCoordinate2D()
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
        //deleteCoredataRecords()
        //deleteCoredataRecords2()
    }
    
    @objc func longTap(sender: UIGestureRecognizer)  {
        print("long tap")
        if sender.state == .began {
            let locationInView = sender.location(in: mapView)
            let locationOnMap = mapView.convert(locationInView, toCoordinateFrom: mapView)
            addAnnotation(location: locationOnMap)
            let albumLoc = self.onTheCallDatabase.saveLocInfo(locationOnMap.latitude, locationOnMap.longitude)
            downloadImagesFromAPI(locationOnMap.latitude, locationOnMap.longitude, albumLoc)
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
        //mapView.removeAnnotations(mapView.annotations)
        var oldPins = [MKPointAnnotation]()
        //oldPins.removeAll()
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
    
    func downloadImagesFromAPI(_ lat:CLLocationDegrees,_ lon:CLLocationDegrees, _ albumLoc:AlbumLocation){
        client.getJson(lat, lon){ (photoSearchResponse, error, success)  in
            DispatchQueue.main.async {
                if success == true{
                    if (photoSearchResponse!.photos.photo.count > 0 ) {
                        //PERSIST ALBUM TO DB
                        //Bug if info icon is clicked before response to first api then we are in trouble
                        for image in photoSearchResponse!.photos.photo{
                            //var photoImage =
                            self.client.downloadImage(image) {(data, error, success) in
                                DispatchQueue.main.async {
                                    self.onTheCallDatabase.saveDownloadedImageDetails(data!, Int32(image.farm), image.server, image.secret, image.id, albumLoc )
                                    
                                }
                            }
                        }
                    }
                    else{
                        let alert = UIAlertController(title:"Unexpected Error", message: "No Images Found", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                        }))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            }
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


//    func deleteCoredataRecords (){
//        let delegate = UIApplication.shared.delegate as! AppDelegate
//        let context = delegate.persistentContainer.viewContext
//
//        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "AlbumLocation")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//
//        do {
//            try context.execute(deleteRequest)
//            try context.save()
//        } catch {
//            print ("There was an error")
//        }
//    }
//
//    func deleteCoredataRecords2 (){
//        let delegate = UIApplication.shared.delegate as! AppDelegate
//        let context = delegate.persistentContainer.viewContext
//
//        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "PhotoImage")
//        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
//
//        do {
//            try context.execute(deleteRequest)
//            try context.save()
//        } catch {
//            print ("There was an error")
//        }
//    }





