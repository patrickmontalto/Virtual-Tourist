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
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    // MARK: Screen dimension properties
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    // Button tint color
    var tintColor: UIColor!
    
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
        
        // Get default tint color
        tintColor = newCollectionButton.tintColor
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
    
    func startAnimatingActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopAnimatingActivityIndicator() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
        }
    }
    
    // MARK: - Get new photos for location
    @IBAction func getNewCollection(sender: AnyObject) {
        
        // Delete selected photos
        if selectedIndexes.count > 0 {
            
            // Delete the items at the indexes in the selectedIndexes
            for index in selectedIndexes {
                sharedContext.deleteObject(fetchedResultsController.objectAtIndexPath(index) as! Photo)
            }
            // Save context
            CoreDataStackManager.sharedInstance().saveContext()
            // Empty indexes and update the button
            selectedIndexes = []
            // Update the button
            toggleNewCollectionButton()
        } else {
            // Delete all photos and get new photos
            
            // Disable button interaction
            newCollectionButton.userInteractionEnabled = false
            
            // Animate activity indicator view
            startAnimatingActivityIndicator()
            
            // Remove current photos for location
            for photo in fetchedResultsController.fetchedObjects as! [Photo] {
                sharedContext.deleteObject(photo)
            }
            // Save context?
            CoreDataStackManager.sharedInstance().saveContext()
            // getLocationPhotos
            getLocationPhotos()
        }
    }
    
    // MARK: - Get Location Photos
    func getLocationPhotos() {
        // Download a new set of photos
        FlickrClient.sharedInstance.getPhotosForLocation(location, completionHandler: {
            success, errorString in
            
            if success {
                
                //save and enable the button
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                    self.newCollectionButton.userInteractionEnabled = true
                })
            } else {
                
                //show error alert and enable button
                dispatch_async(dispatch_get_main_queue(), {
                    // TODO: Display alert to user notifying them of errorString
                    self.newCollectionButton.userInteractionEnabled = true
                })
            }
        })
    }
    
    // MARK: - Core Data Convenience
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Mark: - Fetched Results Controller
    
    // fetchedResultsController
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        //Create fetch request for photos which match the sent Pin.
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pinnedLocation == %@", self.location)
        fetchRequest.sortDescriptors = []
        
        //Create fetched results controller with the new fetch request.
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                  managedObjectContext: self.sharedContext,
                                                                  sectionNameKeyPath: nil,
                                                                  cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()


    // MARK: - Collection View
    
//    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
//        return fetchedResultsController.sections?.count ?? 0
//    }
    
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
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        //add indexPath to appropriate array with type of change
        switch type {
        case .Insert:
            insertedIndexPaths.append(newIndexPath!)
        case .Delete:
            deletedIndexPaths.append(indexPath!)
        case .Update:
            updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }
    
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        //Check to make sure UI elements are correctly displayed.
        if controller.fetchedObjects?.count > 0 {
            newCollectionButton.enabled = true
        }
        
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
            }) { (true) in
                self.stopAnimatingActivityIndicator()
        }
        
//        //Make the relevant updates to the collectionView once Core Data has finished its changes.
//        photoCollectionView.performBatchUpdates({
//            
//            for indexPath in self.insertedIndexPaths {
//                self.photoCollectionView.insertItemsAtIndexPaths([indexPath])
//            }
//            
//            for indexPath in self.deletedIndexPaths {
//                self.photoCollectionView.deleteItemsAtIndexPaths([indexPath])
//            }
//            
//            for indexPath in self.updatedIndexPaths {
//                self.photoCollectionView.reloadItemsAtIndexPaths([indexPath])
//            }
//            
//            }, completion: nil)

        
    }

    
    
    // MARK: - Configure Cell
    func configureCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        //update cell properties
        if photo.image != nil {
            
            cell.activityIndicator.stopAnimating()
            cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            
            UIView.animateWithDuration(0.2,
                                       animations: { cell.imageView.alpha = 1.0 })
        }
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = photoCollectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        toggleSelectedStateForCell(cell, atIndexPath: indexPath)
        toggleNewCollectionButton()
    }
    
    func toggleSelectedStateForCell(cell: PhotoCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        // Either add or remove from index path
        if selectedIndexes.contains(indexPath) {
            // Remove from selected indexes array and reset alpha
            selectedIndexes.removeAtIndex(selectedIndexes.indexOf(indexPath)!)
            cell.alpha = 1.0
        } else {
            selectedIndexes.append(indexPath)
            cell.alpha = 0.5
        }
    }
    
    // MARK: - Toggle button for deletion state
    func toggleNewCollectionButton() {
        if selectedIndexes.count > 0 {
            self.newCollectionButton.tintColor = UIColor.redColor()
            self.newCollectionButton.setTitle("Delete selected photo(s)", forState: .Normal)
        } else {
            self.newCollectionButton.tintColor = tintColor
            self.newCollectionButton.setTitle("New Collection", forState: .Normal)
        }
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