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
        // Set map region for current location
        mapView.region.center = location.coordinate
        let latDelta: CLLocationDegrees = 0.02
        let lonDelta: CLLocationDegrees = 0.02
        mapView.region.span = MKCoordinateSpanMake(latDelta, lonDelta)
        // Disable map user interaction
        // TODO: Load photos for location
    }
    
    @IBAction func getNewCollection(sender: AnyObject) {
        // TODO: Get new photos for location
    }
    
}