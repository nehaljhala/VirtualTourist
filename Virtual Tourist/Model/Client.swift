//
//  Client.swift
//  Virtual Tourist
//
//  Created by Nehal Jhala on 9/8/21.
//

import UIKit
import MapKit

class Client{
    
    var onTheCallDatabase = OnTheCallDatabase()
    
    func getJson(_ lat: Double , _ lon: Double, _ pageNo:Int, completion: @escaping (_ response: structPhotoSearchResponse?, _ error: Error?,_ success: Bool)-> ()) {
        let urlString = "https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=8cdd6874300d5a87adb3d10829a91533&lat=\(lat)&lon=\(lon)&(page)=\(pageNo)&format=json&nojsoncallback=1&per_page=\(50)"
        print("getJson - Fetch Photo List: ", urlString)
        if let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) {data, res, err in
                if let data = data {
                    do {
                        let resp = try JSONDecoder().decode(structPhotoSearchResponse.self, from: data)
                        completion(resp, nil, true)
                    }catch let error {
                        completion(nil, error, false)
                        print("getJson API CALL: api error" + error.localizedDescription)
                    }
                }
            }.resume()
        }
    }
    
    func downloadImage(_ photo: structPhoto, completion: @escaping (_ response: Data? , _ error: Error?,_ success: Bool)-> ())
    {
        let url = URL(string:"https://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.id)_\(photo.secret).jpg" )!
        //print(url.absoluteString)
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                //print("downloadImage API CALL: ")
                completion(data,nil,true)
            }
            else{
                print("downloadImage API CALL Failure: ")
                completion(nil, error, false)
            }
        }.resume()
    }
    
    func downloadImagesFromAPI(_ lat:CLLocationDegrees,_ lon:CLLocationDegrees, _ pageNo:Int, _ albumLoc:AlbumLocation){
        getJson(lat, lon, pageNo){ (photoSearchResponse, error, success)  in
            DispatchQueue.main.async {
                if success == true{
                    self.onTheCallDatabase.saveTotalPhotoCount(albumLoc, Int(photoSearchResponse!.photos.total))
                    if (photoSearchResponse!.photos.photo.count > 0 ) {
                        //PERSIST ALBUM TO DB
                        //Bug if info icon is clicked before response to first api then we are in trouble
                        for image in photoSearchResponse!.photos.photo{
                            //var photoImage =
                            self.downloadImage(image) {(data, error, success) in
                                DispatchQueue.main.async {
                                    self.onTheCallDatabase.saveDownloadedImageDetails(data!, Int32(image.farm), image.server, image.secret, image.id, albumLoc )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}




