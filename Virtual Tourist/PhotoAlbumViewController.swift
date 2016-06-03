//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Patrick on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, NSFetchedResultsControllerDelegate {
    
    // MARK: Location Property
    var location: Pin!
    
    // MARK: IB Outlets
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIButton!
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    // Keep track of tapped for deletion
    var selectedIndexes = [NSIndexPath]()
    
    // Keep track of photos to be downloaded 
    var photosToBeDownloaded = Int()
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // MARK: Screen dimension properties
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set map delegate
        mapView.delegate = self
        
        // Configure layout
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        // Set collectionView delegate & data source
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        // Set map region for current location
        let latDelta: CLLocationDegrees = 0.08
        let lonDelta: CLLocationDegrees = 0.08
        mapView.region.center = location.coordinate
        mapView.region.span = MKCoordinateSpanMake(latDelta, lonDelta)
        
        // Disable map user interaction
        mapView.userInteractionEnabled = false
        
        // Perform the Fetch (initialize lazy var)
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        // Set the delegate to this view controller
        fetchedResultsController.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Place location pin
        mapView.addAnnotation(location)
        
        if location.photos.isEmpty {
            // Start Animating Activity Indicator
            activityIndicator.startAnimating()
            getLocationPhotos()
        }
    }
    
    func stopAnimating() {
        dispatch_async(dispatch_get_main_queue()) {
            print("Stopping animation")
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Get new photos for location
    @IBAction func getNewCollection(sender: AnyObject) {
        // Remove current photos for location
        for photo in fetchedResultsController.fetchedObjects as! [Photo] {
            sharedContext.deleteObject(photo)
        }
        // Save context?
        CoreDataStackManager.sharedInstance().saveContext()
        // getLocationPhotos
        getLocationPhotos()
    }
    
    // MARK: - Get Location Photos
    func getLocationPhotos() {
        FlickrClient.sharedInstance.getPhotosForLocation(location) { (success, photos, errorString) in
            if let errorString = errorString {
                print(errorString)
            } else {
                // Parse the array of movies dictionaries
                let _ = photos!.map() { (dictionary: [String : AnyObject]) -> Photo in
                    // Get imagePath
                    let imagePath = dictionary[FlickrClient.JSONKeys.SmallURL] as! String
                    
                    let photo = Photo(imagePath: imagePath, context: self.sharedContext)
                    
                    photo.pinnedLocation = self.location
                    
                    return photo
                }
                // Update the collectionView on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.photoCollectionView.reloadData()
                })
            }
        }
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "imagePath", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pinnedLocation == %@", self.location);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        return fetchedResultsController
        
    }()

    // MARK: - Collection View
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //Get section info from the fetched results controller...
        if let sectionInfo = fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellIdentifier = "PhotoCell"
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Configure the cell
        configureCell(cell, atIndexPath: indexPath)

        return cell
    }
    
    // TODO: - didSelectItemAtIndexPath
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        print("in controllerWillChangeContent")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            print("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            print("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            print("Update an item")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            print("Move an item. We don't expect to see this in this app.")
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //Check to make sure UI elements are correctly displayed.
        if controller.fetchedObjects?.count > 0 {
            newCollectionButton.enabled = true
        }
        
        //Make the relevant updates to the collectionView once Core Data has finished its changes.
        photoCollectionView.performBatchUpdates({
            
            for indexPath in self.insertedIndexPaths {
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }

            for indexPath in self.updatedIndexPaths {
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil)
    }
    
    
    // MARK: - Configure Cell
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // TODO: Create a photoPlaceholder
        var image = UIImage(named: "photoPlaceholder")
        if photo.imagePath == nil || photo.imagePath == "" {
            // TODO: Create a noImage image placeholder
            image = UIImage(named: "noImage")!
        } else if photo.image != nil {
            image = photo.image!
        }
        
        else {
            // Manually download the image. NOTE: Not using a task here
            FlickrClient.sharedInstance.getImageFromFilePath(photo.imagePath!, completionHandler: { (image, errorString) in
                print("Getting image from filePath...")
                if let errorString = errorString {
                    print(errorString)
                }

                if let image = image {
                    
                    // update the model, so that the information gets cached
                    photo.image = image
                    
                    // Update the cell later, on the main thread
                    dispatch_async(dispatch_get_main_queue()) {
                        print("Setting cell image from getImageFromFilePath")
                        cell.imageView.image = image
                    }
                }
            })
            
        }
        print("setting cell image...")
        cell.imageView.image = image
        
//        if let index = selectedIndexes.indexOf(indexPath) {
//            cell.colorPanel.alpha = 0.05
//        } else {
//            cell.colorPanel.alpha = 1.0
//        }
    }
    
    
    // MARK: - CollectionView Layout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    
        return CGSize(width: (screenWidth - 16) / 3.0, height: (screenWidth - 16) / 3.0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 4
    }
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 4
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        screenWidth = size.width
        photoCollectionView.collectionViewLayout.invalidateLayout()
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    // MARK: Set up pin animation and color
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = UIColor.orangeColor()
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    private func sendNotification(notificationName: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil)
    }

}