//
//  ImageGalleryViewController.swift
//  ImageGallery
//
//  Created by Isaac on 8/8/20.
//  Copyright © 2020 ValentinLagunes. All rights reserved.
//

import UIKit
import MobileCoreServices

class ImageGalleryViewController: UIViewController, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIDropInteractionDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Camera
    
    @IBOutlet weak var cameraButton: UIBarButtonItem! {
        didSet {
            cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera)
        }
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String]
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController?.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = ((info[UIImagePickerController.InfoKey.editedImage] ?? info[UIImagePickerController.InfoKey.originalImage]) as? UIImage)?.scaled(by: 0.25) {
            let localImage = image.jpegData(compressionQuality: 1.0)!
            let localRatio = Double(image.size.width) /
            Double(image.size.height)
            imageCollection.images.insert(ImageInfoModel(imageData: localImage, aspectRatio: localRatio), at: imageCollection.images.count)
            collectionView.reloadData()
            documentDidChange()
        }
        picker.presentingViewController?.dismiss(animated: true)
    }
    
    

    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            let pinch = UIPinchGestureRecognizer(target: self, action: #selector(pinchZoom(_:)))
            collectionView.addGestureRecognizer(pinch)
            collectionView.dragInteractionEnabled = true
        }
    }
    
    @IBOutlet weak var trashIcon: TrashIconView! {
        didSet {
            let dropInteraction = UIDropInteraction(delegate: self)
            trashIcon.addInteraction(dropInteraction)
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
    
    var imageCollection = ImageCollection() {
        didSet {
            if oldValue.images != imageCollection.images {
                print("didChange")
                documentDidChange()
            }
        }
    }
    
    func documentDidChange() {
        document?.imageGalleryCollec = imageCollection
        if document?.imageGalleryCollec != nil {
            document?.updateChangeCount(.done)
            document?.save(to: document!.fileURL, for: .forOverwriting)
        }
    }

    var document : ImageGalleryDocument?
    
    //MARK: LifeCycle
    
    override func viewDidLayoutSubviews() {
        //collectionView.reloadData()
    }
    
     override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
     //   if document?.documentState != .normal
      //  {
            document?.open { success in
                if success {
                    self.title = self.document?.localizedName
                    self.imageCollection = self.document?.imageGalleryCollec ?? ImageCollection()
                    self.collectionView.reloadData()
                }
                
            }
       // }
    }
    
    var thumbnailImage : UIImage?
    
    @IBAction func close(_ sender: UIBarButtonItem) {
        documentDidChange()
        document?.thumbnail = thumbnailImage
        dismiss(animated: true) {
            self.document?.close()
        }
    }
    
//    @IBAction func save(_ sender: UIBarButtonItem? = nil) {
//        document?.imageGalleryCollec = imageCollection
//        if document?.imageGalleryCollec != nil {
//            document?.updateChangeCount(.done)
//        }
//    }
    
    
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
            //mark index path to delete it easier later
            imageCollection.images[indexPath.item].indPath = indexPath
            dragItem.localObject = imageCollection.images[indexPath.item]
            return [dragItem]
        } else {
            return []
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //MARK: CollectionViewDelegate Methods
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: standardWidth, height: standardWidth/CGFloat(imageCollection.images[indexPath.item].ratio))
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
                        imageCollection.images.remove(at: sourceIndexPath.item)
                        imageCollection.images.insert(imageModelCell, at: destinationIndexPath.item)
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
                                    self.imageCollection.images.insert(ImageInfoModel(url: localURL!, aspectRatio: localRatio!), at: insertionIndexPath.item)
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
        imageCollection.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath)
        
        if let currCell = cell as? ImageCollectionViewCell {
            //check if it was a local image first
            if imageCollection.images[indexPath.item].isLocalImage
            {
                currCell.cellImage = UIImage(data: imageCollection.images[indexPath.item].imageData!)
            }
            else
            {
                //cached responses
                let tempURL = imageCollection.images[indexPath.item].myURL!.imageURL
                currCell.imageURL = tempURL
                let request = URLRequest(url: tempURL)
                //currCell.imageURL = imageCollection.images[indexPath.item].myURL.imageURL
                var cache = URLCache.shared
                //about 10 megabytes and 100 megabytes for about 10 images in memory and 100 in disk
                cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024, diskPath: nil)
                
                // DispatchQueue.global(qos: .userInitiated).async {
                if let data = cache.cachedResponse(for: request)?.data, let image = UIImage(data: data) {
                    //found image in my cache
                    currCell.cellImage = image
                    //putting in most recent thumbnail
                    if currCell.imageURL == self.imageCollection.images[self.imageCollection.images.count - 1].myURL {
                        self.thumbnailImage = image
                    }
                }
                else //didn't find it in cache
                {
                    currCell.spinner.isHidden = false
                    currCell.spinner.startAnimating()
                    DispatchQueue.global(qos: .userInitiated).async {
                        URLSession.shared.dataTask(with: request) { (data, response, error) in
                            DispatchQueue.main.async { 
                                if let data = data, let response = response, error == nil {
                                    let cachedData = CachedURLResponse(response: response, data: data)
                                    cache.storeCachedResponse(cachedData, for: request)
                                    
                                    currCell.cellImage = UIImage(data: data)
                                    //putting in most recent thumbnail
                                    if currCell.imageURL == self.imageCollection.images[self.imageCollection.images.count - 1].myURL {
                                        self.thumbnailImage = currCell.cellImage
                                    }
                                }
                                //currCell.spinner.stopAnimating()
                                // currCell.spinner.isHidden = true
                            }
                        }.resume()
                        // }
                    }
                }
            }
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
                if url != nil
                {
                    imageVC.imageURL = url
                }
                else
                {
                    imageVC.imageView.image = imCell.cellImage
                    imageVC.image = imCell.cellImage
                }
            }
        }
        
    }
    
    //MARK: Trash UIDropInteraction Delegate
    
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
            return session.canLoadObjects(ofClass: UIImage.self)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {

        return UIDropProposal(operation: .copy)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        session.loadObjects(ofClass: UIImage.self) { images in
            let items = session.localDragSession?.items
            for item in items ?? [] {
                let draggedImage = item.localObject as? ImageInfoModel
                self.collectionView.performBatchUpdates({
                    if self.imageCollection.images.contains(draggedImage!) {
                        let indPath = draggedImage?.indPath
                        //print("Index Path: \(indPath)")
                        self.collectionView.deleteItems(at: [indPath!])
                        self.imageCollection.images.remove(at: self.imageCollection.images.firstIndex(of: draggedImage!)!)
                        //self.collectionView.reloadData()
                    }
                }, completion: { error in
                    self.documentDidChange()
                })
            }

        }
    }
    
}
