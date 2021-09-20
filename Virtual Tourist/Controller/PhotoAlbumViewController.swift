//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Nehal Jhala on 8/19/21.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate,UICollectionViewDataSource, MKMapViewDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var newCollButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var albumLocation: AlbumLocation!
    var images = [PhotoImage]()
    var onTheCallDatabase = OnTheCallDatabase()
    var lat = Double()
    var lon = Double()
    var zoomMapLocation = CLLocationCoordinate2D()
    let client = Client()
    var delay:Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView!.reloadData()
        let space:CGFloat = 3.0
        let cellWidth = (view.frame.size.width - (2 * space)) / 3.0
        let cellHeight = (view.frame.size.height - (2 * space)) / 3.0
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        self.mapView.addAnnotations([annotation])
        NotificationCenter.default.addObserver(self, selector: #selector(finishedDownload), name: .didFinishSave, object: nil)
        setZoomOnMap(CLLocationCoordinate2DMake(lat, lon), map: mapView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.delay = false
            self.collectionView.reloadData()
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        newCollButton.isEnabled = false
    }
    
    @objc func finishedDownload(){
        newCollButton.isEnabled = true
        self.images = onTheCallDatabase.fetchImage(albumLocation)
        collectionView.reloadData()
        
    }
    
    //zoom on region:
    func setZoomOnMap(_ location: CLLocationCoordinate2D, map mapName: MKMapView) {
        var region = MKCoordinateRegion()
        var spanCoordinate = MKCoordinateSpan()
        spanCoordinate.latitudeDelta = 0.002
        spanCoordinate.longitudeDelta = 0.003
        region.span = spanCoordinate
        region.center = location
        mapName.setRegion(region, animated: true)
        mapName.regionThatFits(region)
        mapName.isZoomEnabled = true
    }
    
    //MapViewDelegate:
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        if(delay==false) {
            cell.imageView.image = UIImage(data: (images[indexPath.row].image)!)
            cell.indicator.stopAnimating()
            cell.indicator.isHidden = true
            self.newCollButton.isEnabled = true
        }
        else {
            cell.indicator.isHidden = false
            cell.indicator.startAnimating()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView , didSelectItemAt indexPath: IndexPath){
        self.collectionView.deleteItems(at: [indexPath])
        //delete from coredata:
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context: NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        context.delete(images[indexPath.row])
        images.remove(at: indexPath.row)
        do{
            try context.save()
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
    }
    
    
    @IBAction func newCollButtonTapped(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context: NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        for image in images {
            context.delete(image)
        }
        images.removeAll()
        do{
            try context.save()
        } catch let error as NSError {
            print("Could not delete. \(error), \(error.userInfo)")
        }
        let pageCount:Int64 = albumLocation.imageCount/50 + 1
        client.downloadImagesFromAPI(lat, lon, Int.random(in: 1...Int(pageCount)), albumLocation)
        self.collectionView.reloadData()
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
}


