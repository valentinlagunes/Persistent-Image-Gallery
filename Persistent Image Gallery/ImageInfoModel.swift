//
//  ImageInfo.swift
//  ImageGallery
//
//  Created by Isaac on 8/11/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import Foundation

struct ImageInfoModel {
    init(url: URL, aspectRatio: Double) {
        myURL = url
        ratio = aspectRatio
    }
    var myURL : URL
    var ratio : Double
    
}
