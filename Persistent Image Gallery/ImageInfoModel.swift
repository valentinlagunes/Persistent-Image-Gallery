//
//  ImageInfo.swift
//  ImageGallery
//
//  Created by Isaac on 8/11/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import Foundation

struct ImageInfoModel : Codable , Equatable {
    init(url: URL, aspectRatio: Double) {
        myURL = url
        ratio = aspectRatio
        //indPath = IndexPath()
    }
    
    init(imageData: Data, aspectRatio: Double)
    {
        self.imageData = imageData
        self.ratio = aspectRatio
        self.isLocalImage = true
        
    }
    
    var myURL : URL?
    var imageData : Data?
    var ratio : Double
    var indPath = IndexPath()
    var isLocalImage = false
    
    static func == (lhs: ImageInfoModel, rhs: ImageInfoModel) -> Bool {
        return lhs.myURL == rhs.myURL
    }
    
}

protocol ImageCollectionDelegate {
    func ImageCollectionDidChange(_ sender: ImageCollection)
}

struct ImageCollection : Codable {
    
    var images = [ImageInfoModel]()
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }
    
    init() {
        self.images = []
    }
    
    init(images: [ImageInfoModel]) {
        self.images = images
    }
    
    init?(json: Data) {
        if let newValue = try? JSONDecoder().decode(ImageCollection.self, from: json) {
            self = newValue
        }
        else{
            return nil
        }
    }
}
