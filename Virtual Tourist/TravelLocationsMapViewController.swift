//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/26/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {
    
    @IBOutlet var mapView: MKMapView!
    
    var editView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // set mapView Delegate
        mapView.delegate = self
        
        // Add Edit button to Nav Bar
        navigationItem.rightBarButtonItem = editButtonItem()
        
        // Add edit instructions view
        configureEditView()
        
        // Add UILongPressGestureRecognizer to mapView
        configureGestureRecognizer()
        
        // Load last user region
        loadMapRegion()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Populate Map with Core Data pins
        mapView.addAnnotations(fetchAllPins())
    }
    // MARK: - Allow editing on MapView
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        // Slide up from bottom to show directions: "Tap to remove Pin"
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.translateVerticalForEditingState(editing)
            }, completion: nil)
    }
    
    func placePin(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state != .Began {
            return
        }
        let touchPoint = gestureRecognizer.locationInView(mapView)
        
        let touchedCoordinate = coordinateForPoint(touchPoint)

        // Create pin
        let pin = Pin(latitudeDouble: touchedCoordinate.latitude, longitudeDouble: touchedCoordinate.longitude, context: sharedContext)
        // Add pin to the map
        mapView.addAnnotation(pin)
        // Begin getting photos for Pin
        fetchPhotosForPin(pin)
        // Save context
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func fetchAllPins() -> [Pin] {
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        // Execute the Fetch Request
        do {
            let results = try sharedContext.executeFetchRequest(fetchRequest)
            return results as! [Pin]
        } catch let error as NSError {
            print("Error: \(error.localizedDescription)")
            return [Pin]()
        }
    }
    
    // fetch all photos for a selected Pin
    func fetchPhotosForPin(pin: Pin) {
        // TODO: Debugging
        FlickrClient.sharedInstance.getPhotosForLocation(pin, completionHandler: {
            success, errorString in
            
            if success {
                
                //save the new Photo to Core Data
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            } else {
                
                dispatch_async(dispatch_get_main_queue(), {
                    // TODO: Error with request.
                })
            }
        })
    }
    
    // MARK: Translate View for Editing Instructions
    private func translateVerticalForEditingState(editing: Bool) {
        let translationHeight: CGFloat = editing ? -60 : 60
        mapView.frame.origin.y += translationHeight
        editView.frame.origin.y += translationHeight
    }
    
    // MARK: Set up edit view for user instructions
    private func configureEditView() {
        // Create editView
        editView = UIView()
        editView.backgroundColor = UIColor.redColor()
        editView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set editView height
        let editView_constraint_V = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:[editView(60)]",
            options: NSLayoutFormatOptions(rawValue: 0),
            metrics: nil, views: ["editView":editView])
        
        editView.addConstraints(editView_constraint_V)
        
        // Add Label
        let label = UILabel(frame: CGRectMake(0,0, 250, 24))
        label.text = "Tap Pin to Delete"
        label.font = UIFont.systemFontOfSize(20.0, weight: UIFontWeightMedium)
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        label.center = CGPointMake(view.frame.size.width / 2, editView.frame.size.height / 2 + 30)
        editView.addSubview(label)
        
        // Add  to view
        view.addSubview(editView)
        
        // Constraints
        NSLayoutConstraint(item: editView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .TrailingMargin, multiplier: 1.0, constant: 20.0).active = true
        NSLayoutConstraint(item: editView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .LeadingMargin, multiplier: 1.0, constant: -20.0).active = true
        NSLayoutConstraint(item: editView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .BottomMargin, multiplier: 1.0, constant: 60.0).active = true
        
    }
    
    // MARK: Set up map gesture recognizer
    private func configureGestureRecognizer() {
        // Add a Gesture Recognizer for a long press
        let uilpgr = UILongPressGestureRecognizer(target: self, action: "placePin:")

        // Set minimum press duration for gesture recognizer
        uilpgr.minimumPressDuration = 1
        
        // Add gesture recognizer to the mapView
        mapView.addGestureRecognizer(uilpgr)
    }
    
    // MARK: Coordinate for Touchpoint
    private func coordinateForPoint(point: CGPoint) -> CLLocationCoordinate2D {
        return mapView.convertPoint(point, toCoordinateFromView: mapView) as CLLocationCoordinate2D
    }
    
    // MARK: - User Map Region
    
    // MARK: Save Region
    
    func saveMapRegion() {
        // Get Standard User Defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // Save lat, lon, latDelta, and lonDelta for mapView
        defaults.setObject(mapView.region.center.latitude, forKey: "Latitude")
        defaults.setObject(mapView.region.center.longitude, forKey: "Longitude")
        defaults.setObject(mapView.region.span.latitudeDelta, forKey: "LatitudeDelta")
        defaults.setObject(mapView.region.span.longitudeDelta, forKey: "LongitudeDelta")
    }
    
    // MARK: Load Region
    func loadMapRegion() {
        // Get Standard User Defaults
        let defaults = NSUserDefaults.standardUserDefaults()
        
        // GUARD: Get lat, lon, latDelta, lonDelta
        guard let latitude = defaults.objectForKey("Latitude") as? CLLocationDegrees, let longitude = defaults.objectForKey("Longitude") as? CLLocationDegrees, let latDelta = defaults.objectForKey("LatitudeDelta") as? CLLocationDegrees, let lonDelta = defaults.objectForKey("LongitudeDelta") as? CLLocationDegrees else {
            return
        }
        // Set mapView region and span
        mapView.region.center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mapView.region.span = MKCoordinateSpanMake(latDelta, lonDelta)
    }
    
    // MARK: - Core Data Convenience
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // MARK: - Present PhotoAlbumViewController
    func presentPhotoAlbumForLocation(location: Pin) {
        // TODO: Change editing to false?
        
        // Instantiate view controller
        let photoAlbumViewController = storyboard?.instantiateViewControllerWithIdentifier("PhotoAlbumViewController") as! PhotoAlbumViewController
        // Set location pin for controller
        photoAlbumViewController.location = location
        // Present view controller
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
}


// MARK: - MKMapViewDelegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    
    // MARK: Save region when regionDidChange occurs
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    // MARK: Set up pin animation and color
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.pinTintColor = UIColor.orangeColor()
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // MARK: Delete Pin
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // GUARD: Is there an annotation for the mapView?
        guard let pin = view.annotation as? Pin else {
            return
        }
        
        if editing {
            // Remove pin from the context
            sharedContext.deleteObject(pin)
            // Animate pin removal
            mapView.removeAnnotation(pin, animated: true)
            // Save context
            CoreDataStackManager.sharedInstance().saveContext()
            
           // view.removeFromSuperview()
        } else {
            // Deselect current pin
            mapView.deselectAnnotation(view.annotation!, animated: false)
            // Present photo album for pin
            presentPhotoAlbumForLocation(pin)
        }
    }
}












