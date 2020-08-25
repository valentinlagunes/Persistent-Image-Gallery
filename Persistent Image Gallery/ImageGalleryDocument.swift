//
//  Document.swift
//  Persistent Image Gallery
//
//  Created by Isaac on 8/25/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
    
    var imageGalleryCollec : ImageCollection?
    
    override func contents(forType typeName: String) throws -> Any {
        // Encode your document with an instance of NSData or NSFileWrapper
        return imageGalleryCollec?.json ?? Data()
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        // Load your document from contents
        if let json = contents as? Data {
            imageGalleryCollec = ImageCollection(json: json)
        }
    }
}

