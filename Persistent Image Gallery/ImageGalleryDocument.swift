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
    
    override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
        var attributes = try super.fileAttributesToWrite(to: url, for: saveOperation)
//        if let thumbnail = self.thumbnail {
//            attributes[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey:thumbnail]
//        }
        return attributes
    }
}

