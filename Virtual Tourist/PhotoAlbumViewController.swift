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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    // MARK: IB Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIButton!
    
    // TODO: Add UIActivityIndicatorView
    
    // MARK: Location Property
    var location: Pin!
    
    // MARK: Screen dimension properties
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    // MARK: NSFetchedResultsController Delegate Properties
    var insertedIndexPaths: [NSIndexPath]?
    var deletedIndexPaths: [NSIndexPath]?
    var updatedIndexPaths: [NSIndexPath]?
    
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
        
        // Subscribe to notifcation so photos can be loaded as they're downloaded
       // NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(PhotoAlbumViewController.reloadPhotos), name: "imageDidFinishDownloading", object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Place location pin
        mapView.addAnnotation(location)
        
        if location.photos.isEmpty {
            getLocationPhotos()
        }
    }
    
    func reloadPhotos() {
        dispatch_async(dispatch_get_main_queue()) {
            self.photoCollectionView.reloadData()
        }
    }
    
    // MARK: - Get new photos for location
    @IBAction func getNewCollection(sender: AnyObject) {
        // Remove current photos for location
        // let photos = fetchedResultsController.fetchedObjects as! [Pin]
        let photos = location.photos
        // Remove from context?
        for photo in photos {
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
            if success, let photos = photos {
                print("GETTING NEW PHOTOS FOR LOCATION...")
                // Parse the array of photo dictionaries
                let _ = photos.map({ (dictionary: [String:AnyObject]) -> Photo in
                    // Get imagePath
                    let imagePath = dictionary[FlickrClient.JSONKeys.SmallURL] as! String
                    
                    // Create photo
                    let photo = Photo(imagePath: imagePath, context: self.sharedContext)
                    
                    // Associate pin with photo
                    photo.pinnedLocation = self.location
                    
                    return photo
                })
                
                // Update the collection view on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    // Perform the Fetch
                    do {
                        try self.fetchedResultsController.performFetch()
                    } catch {}
                    
                    self.photoCollectionView.reloadData()
                })
                
                // Save context
                CoreDataStackManager.sharedInstance().saveContext()
                
            } else {
                print(errorString!)
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
    
    // The three collection view methods
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cellIdentifier = "PhotoCell"
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        // Configure the cell
        configureCell(cell, photo: photo)

        return cell
    }
    
    
    
    // MARK: - Configure Cell
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        var photoImage = UIImage()
        
        if photo.image != nil {
            cell.activityIndicator.stopAnimating()
            photoImage = photo.image!
        } else {
            // TODO: Set placeholder image with UIActivityIndicatorView:
            
            // Get image from file path:
            FlickrClient.sharedInstance.getImageFromFilePath(photo.imagePath, completionHandler: { (image, errorString) in
                if let image = image {
                    // Set photoImage
                    photoImage = image
                    
                    // Update the photo model
                    photo.image = photoImage
                    
                } else {
                    // Print the error string
                    print(errorString!)
                }
            })
            
            // update the cell
            print("2. Updating the cell.")
            cell.imageView!.image = photoImage
        }
        
        cell.frame.size.width = (screenWidth - 16) / 3.0
        cell.frame.size.height = (screenWidth - 16) / 3.0
        print("3. Setting the image and stop animating.")
        cell.imageView!.image = photoImage
        cell.activityIndicator.stopAnimating()
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

}

// MARK: Fetched Results Controller Protocol
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            insertedIndexPaths!.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths!.append(indexPath!)
        case .Update:
            updatedIndexPaths!.append(indexPath!)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        if controller.fetchedObjects?.count > 0 {
            // Hide no images label
            // Enable new photo collection button
        }
        
        photoCollectionView.performBatchUpdates({
            for indexPath in self.insertedIndexPaths! {
                print("inserting...")
                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.deletedIndexPaths! {
                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
            }
            for indexPath in self.updatedIndexPaths! {
                print("updating...")
                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
            }
            }, completion: nil)
    }
}