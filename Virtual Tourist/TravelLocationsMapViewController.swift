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
    
    var pins: [Pin]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add Edit button to Nav Bar
        navigationItem.rightBarButtonItem = editButtonItem()
        
        // Add edit instructions view
        configureEditView()
        
        // Add UILongPressGestureRecognizer to mapView
        configureGestureRecognizer()
        
        // Load last user region
        loadMapRegion()
        
        // Load Pins
        pins = fetchAllPins()
        
        // Populate Map with Core Data pins
        placeSavedPins()
    }
    
    // MARK: - Allow editing on MapView
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        // Slide up from bottom to show directions: "Tap to remove Pin"
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.translateVerticalForEditingState(editing)
            }, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func placePin(gestureRecognizer:UIGestureRecognizer) {
        if gestureRecognizer.state != .Began {
            return
        }
        let touchPoint = gestureRecognizer.locationInView(mapView)

        let annotation = annotationForTouchPoint(touchPoint)
        
        mapView.addAnnotation(annotation)
        
        // Add annotation ("Pin") to core data here
        let pinDictionary = [Pin.Keys.Latitude : annotation.coordinate.latitude, Pin.Keys.Longitude : annotation.coordinate.latitude]
        let pin = Pin(dictionary: pinDictionary, context: sharedContext)
        pins.append(pin)
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    func placeSavedPins() {
        var annotations = [MKPointAnnotation]()
        print("pins count:\(pins.count)")
        for pin in pins {
            let lat = CLLocationDegrees(pin.latitude)
            let lon = CLLocationDegrees(pin.longitude)
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        // TODO: Figure out why these aren't being added...
        mapView.addAnnotations(annotations)
        print("annotation count:\(mapView.annotations.count)")
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
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(TravelLocationsMapViewController.placePin(_:)))
        
        // Set minimum press duration for gesture recognizer
        uilpgr.minimumPressDuration = 1
        
        // Add gesture recognizer to the mapView
        mapView.addGestureRecognizer(uilpgr)
    }
    
    // MARK: Build annotation for selected point
    private func annotationForTouchPoint(touchPoint: CGPoint) -> MKPointAnnotation {
        
        let newCoordinate: CLLocationCoordinate2D = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        let annotation = MKPointAnnotation()
        
        annotation.coordinate = newCoordinate
        
        return annotation
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
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchAllPins: \(error.localizedDescription)")
            return [Pin]()
        }
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
        print("Selected!")
        if editing {
            // GUARD: Is there an annotation for the mapView?
            guard let annotation = view.annotation else {
                return
            }
            
            // TODO: Find Pin object in array using coordinates
            let latitude = annotation.coordinate.latitude
            let longitude = annotation.coordinate.longitude
            
            let pin = pins.filter(){$0.latitude == latitude && $0.longitude == longitude}.first!
            let index = pins.indexOf(pin)
            // Remove pin from the array
            pins.removeAtIndex(index!)
            // Remove pin from the context
            sharedContext.deleteObject(pin)
            // Save context
            CoreDataStackManager.sharedInstance().saveContext()
            
            view.removeFromSuperview()
        }
    }
}












