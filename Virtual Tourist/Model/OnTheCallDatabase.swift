//
//  OnTheCallDatabase.swift
//  Virtual Tourist
//
//  Created by Nehal Jhala on 9/10/21.
//
import UIKit
import Foundation
import CoreData

class OnTheCallDatabase{
    
    var result = [NSManagedObject]()
    
    //Fetch All Lat/Long Album records
    func fetchLocDetails () -> [AlbumLocation]{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context:NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        var _: NSError? = nil
        let fReq: NSFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AlbumLocation")
        fReq.returnsObjectsAsFaults = false
        do {
            result = try context.fetch(fReq)
            // print("fetchLocDetails: ", result)
        } catch let error as NSError {
            print("fetchLocDetails: \(error), \(error.userInfo)")
        }
        return result as! [AlbumLocation]
    }
    
    //Fetch all images for a given AlbumLocation
    func fetchImage (_ albumLocation:AlbumLocation) -> [PhotoImage]{
        var imageResult = [NSManagedObject]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context:NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        var _: NSError? = nil
        let predicate = NSPredicate(format: "locaGrp = %@", albumLocation)
        let fReq: NSFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "PhotoImage")
        fReq.returnsObjectsAsFaults = false
        fReq.predicate = predicate
        do {
            imageResult = try context.fetch(fReq)
        } catch let error as NSError {
            print("fetchImage: \(error), \(error.userInfo)")
        }
        return imageResult as! [PhotoImage]
    }
    
    //Fetches single Album Location
    func fetchAlbumLocation (_ latitude:CLLocationDegrees, _ longitude: CLLocationDegrees) -> AlbumLocation{
        var albumResult = [NSManagedObject]()
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context:NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        var _: NSError? = nil
        let latPredicate = NSPredicate(format: "abs:(lat - %lf) < 0.000001", latitude)
        let lonPredicate = NSPredicate(format: "abs:(lon - %lf) < 0.000001", longitude)
        let fReq: NSFetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AlbumLocation")
        fReq.returnsObjectsAsFaults = false
        fReq.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [latPredicate, lonPredicate])
        do {
            albumResult = try context.fetch(fReq)
        } catch let error as NSError {
            print("fetchImage: \(error), \(error.userInfo)")
        }
        return albumResult[0] as! AlbumLocation
    }
    
    //save in AlbumLocation:
    func saveLocInfo(_ lat: CLLocationDegrees, _ lon: CLLocationDegrees) -> AlbumLocation{
        //persistent container:
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context:NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        let albumLoc = AlbumLocation(context: context)
        albumLoc.lat = lat
        albumLoc.lon = lon
        do {
            try context.save()
        } catch let error as NSError{
            print("saveLocInfo: \(error), \(error.userInfo).")
        }
        return albumLoc
    }
    
    
    func saveTotalPhotoCount(_ albumLoc: AlbumLocation, _ totalPhotos: Int){
        var context: NSManagedObjectContext {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            return appDelegate.persistentContainer.viewContext
        }
        albumLoc.imageCount = Int64(totalPhotos)
        do {
            print("totalimages ",albumLoc.imageCount)
            try context.save()
        } catch let error as NSError{
            print("saveLocInfo: \(error), \(error.userInfo).")
        }
    }
    
    //Save image for a given album location
    func  saveDownloadedImageDetails(_ downloadedImage: Data, _ farm: Int32, _ server: String, _ secret: String, _ id: String, _ albumLoc: AlbumLocation) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        var context:NSManagedObjectContext!
        context = appDelegate.persistentContainer.viewContext
        let photoImage = PhotoImage(context:context)
        photoImage.image = downloadedImage
        photoImage.farm = farm
        photoImage.server = server
        photoImage.secret = secret
        photoImage.id = id
        albumLoc.addToImagesGrp(photoImage)
        do {
            try context.save()
            NotificationCenter.default.post(name: .didFinishSave, object: nil)
        } catch let error as NSError{
            print("saveDownloadedImageDetails: \(error), \(error.userInfo).")
        }
    }
    
}
