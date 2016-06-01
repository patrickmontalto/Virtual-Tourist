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

class PhotoAlbumViewController: UIViewController {
    
    // MARK: IB Outlets
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var photoCollectionView: UICollectionView!
    @IBOutlet var newCollectionButton: UIButton!
    
    // MARK: Location Property
    var location: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set map delegate
        mapView.delegate = self
        
        // Set map region for current location
        let latDelta: CLLocationDegrees = 0.02
        let lonDelta: CLLocationDegrees = 0.02
        mapView.region.center = location.coordinate
        mapView.region.span = MKCoordinateSpanMake(latDelta, lonDelta)
        
        // Disable map user interaction
        mapView.userInteractionEnabled = false
        
        // TODO: Load photos for location
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Place location pin
        mapView.addAnnotation(location)
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
        // TODO: Get new photos for location
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