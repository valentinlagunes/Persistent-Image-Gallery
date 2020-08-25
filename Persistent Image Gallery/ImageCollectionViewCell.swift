//
//  ImageCollectionViewCell.swift
//  ImageGallery
//
//  Created by Isaac on 8/10/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    var imageURL: URL? {
        didSet {
            fetchImage()
        }
    }
    private var cellImage: UIImage? {
        get {
            return imageView.image
        }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            
     //       scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
            spinner.isHidden = true
        }
    }
    
    private func fetchImage() {
        if let url = imageURL {
            imageView.image = nil
            spinner.isHidden = false
            spinner.startAnimating()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let urlContents = try? Data(contentsOf: url)
                DispatchQueue.main.async {
                    if let imageData = urlContents, url == self?.imageURL {
                        self?.cellImage = UIImage(data: imageData)
                    }
                }
            }

        }
    }
    
    
}
