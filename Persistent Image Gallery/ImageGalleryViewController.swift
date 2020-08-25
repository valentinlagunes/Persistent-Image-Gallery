//
//  ImageGalleryViewController.swift
//  ImageGallery
//
//  Created by Isaac on 8/8/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchZoom(_:)))
            collectionView.addGestureRecognizer(pinch)
        }
    }
    
    lazy private var minWidth = collectionView.frame.width / 10
    lazy private var maxWidth = collectionView.frame.width * 0.95
    
    @objc func pinchZoom(_ recognizer: UIPinchGestureRecognizer) {
        //print("pinched")
        //print(recognizer.velocity)
        if recognizer.state == .changed
        {
            if recognizer.velocity > 0.1 && standardWidth < maxWidth
            {
                standardWidth += 3 * recognizer.velocity
            } else if recognizer.velocity < -0.1 && standardWidth > minWidth{
                standardWidth += 3 * recognizer.velocity
            }
            flowLayout?.invalidateLayout()
            //collectionView.reloadData()
        }
        
    }
    
    
    //fit about five images per row
    lazy var standardWidth = collectionView.frame.width / 5
    var imageCollection : ImageCollection?

    var document : ImageGalleryDocument?
    
    //MARK: LifeCycle
    
    override func viewDidLayoutSubviews() {
        //collectionView.reloadData()
    }
    
     override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        document?.open { success in
            if success {
                self.title = self.document?.localizedName
                self.imageCollection = self.document?.imageCollec
            }
            
        }
    }
    
    
    var flowLayout: UICollectionViewFlowLayout? {
        return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
    }
    
    //segue to full image view
    @objc func tapSegue(recognizer: UITapGestureRecognizer) {
        if let indexPath = collectionView.indexPathForItem(at: recognizer.location(in: collectionView)) {
            let cell = collectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell
            performSegue(withIdentifier: "FullImage", sender: cell)
        }
    }
    
    private func dragItems(at indexPath: IndexPath) -> [UIDragItem] {
        //drag around an ImageModel
        if let itemCell = collectionView?.cellForItem(at: indexPath)
            as? ImageCollectionViewCell,
            let image = itemCell.imageView.image {
            let dragItem = UIDragItem(itemProvider: NSItemProvider(object: image))
            dragItem.localObject = imageCollection!.images[indexPath.item]
            return [dragItem]
        } else {
            return []
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: standardWidth, height: standardWidth/CGFloat(imageCollection!.images[indexPath.item].ratio))
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        session.localContext = collectionView
        return dragItems(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(item: 0, section: 0)
        for item in coordinator.items {
            //local object
            if let sourceIndexPath = item.sourceIndexPath {
                if let imageModelCell = item.dragItem.localObject as? ImageInfoModel {
                    collectionView.performBatchUpdates({
                        imageCollection!.images.remove(at: sourceIndexPath.item)
                        imageCollection!.images.insert(imageModelCell, at: destinationIndexPath.item)
                        collectionView.deleteItems(at: [sourceIndexPath])
                        collectionView.insertItems(at: [destinationIndexPath])
                    })
                    coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
                }
            } else { //dragging in image from the internet
                let placeholderContext = coordinator.drop(item.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: "DropPlaceholderCell"))
                var localURL : URL?
                var localRatio : Double?
                //store image ratio
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) {
                    (provider, error) in
                    DispatchQueue.main.async {
                        if let image = provider as? UIImage {
                            localRatio = Double(image.size.width) /
                                Double(image.size.height)
                        }
                    }
                }
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) {(provider, error) in
                    //store image url
                    DispatchQueue.main.async {
                        if let url = provider as? URL {
                            localURL = url.imageURL
                            placeholderContext.commitInsertion(dataSourceUpdates: {insertionIndexPath in
                                if localRatio != nil && localURL != nil
                                {
                                    self.imageCollection!.images.insert(ImageInfoModel(url: localURL!, aspectRatio: localRatio!), at: insertionIndexPath.item)
                                }
                            })
                        } else {
                            placeholderContext.deletePlaceholder()
                        }
                    }
                }
            }
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        imageCollection!.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        
        if let currCell = cell as? ImageCollectionViewCell {
            currCell.imageURL = imageCollection!.images[indexPath.item].myURL.imageURL
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapSegue(recognizer:)))
            tap.numberOfTapsRequired = 1
            tap.numberOfTouchesRequired = 1
            cell.addGestureRecognizer(tap)
            flowLayout?.invalidateLayout()
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        if isSelf {
            return session.canLoadObjects(ofClass: UIImage.self)
        }
        return session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        let isSelf = (session.localDragSession?.localContext as? UICollectionView) == collectionView
        return UICollectionViewDropProposal(operation: isSelf ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let imCell = sender as? ImageCollectionViewCell {
           
            let url = imCell.imageURL
            var destination = segue.destination
            if let navcon = destination as? UINavigationController {
                destination = navcon.visibleViewController ?? navcon
            }
            if let imageVC = destination as? ImageFullViewController {
                imageVC.imageURL = url
            }
        }
        
    }
    
    
}
