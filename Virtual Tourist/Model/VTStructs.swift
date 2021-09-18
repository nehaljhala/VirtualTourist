//
//  VTStructs.swift
//  Virtual Tourist
//
//  Created by Nehal Jhala on 9/8/21.
//

import Foundation
struct structPhotoSearchResponse: Codable{
    var photos: structPhotos
}
struct structPhotos: Codable{
    var photo: [structPhoto]
}
struct structPhoto: Codable{
    var id: String
    var secret: String
    var server: String
    var farm: Int
}
