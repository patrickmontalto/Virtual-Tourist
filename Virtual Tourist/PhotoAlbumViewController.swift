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

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: IB Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIButton!
    
    // TODO: Add UIActivityIndicatorView
    
    // MARK: Location Property
    var location: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set map delegate
        mapView.delegate = self
        
        // Set collectionView delegate & data source
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        
        // Set map region for current location
        let latDelta: CLLocationDegrees = 0.02
        let lonDelta: CLLocationDegrees = 0.02
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
            getLocationPhotos()
        }
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
        // TODO: Get new photos for location
    }
    
    // MARK: - Get Location Photos
    func getLocationPhotos() {
        FlickrClient.sharedInstance.getPhotosForLocation(location) { (success, photos, errorString) in
            if success, let photos = photos {
                print("Photo count:\(photos.count)")
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
                    self.photoCollectionView.reloadData()
                })
                
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
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath)
        
        // Configure the cell
        //configureCell()
        
        return cell
    }
    
    
    
    // MARK: - Configure Cell
    func configureCell(cell: TaskCancelingCollectionViewCell, photo: Photo) {
        var photoImage = UIImage() // TODO: photo placeholder?
        if photo.image == nil {
            photoImage = UIImage(named: "photoPlaceholder")!
        }else if photo.image != nil {
            photoImage = photo.image!
        } else { // When the photo has an image name, but it is not downloaded yet
            // TODO: Create Flickr getImageFromFilePath:
            // let data = data and create a UIImage from the data.
            // Update the photo model
            // update the cell on the main thread
            
            // cancel the task when cell is reused
        }
        
        // cell.imageView.image = photoImage ??
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