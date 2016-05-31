//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/27/16.
//  Copyright © 2016 swift. All rights reserved.
//

import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let Photos = "photos"
    }
    
    // MARK: Core Data Attributes
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var photos: [Photo]
    
    // MARK: Standard Core Data Init Method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: Two argument Init Method
    init(latitudeDouble: Double, longitudeDouble: Double, context: NSManagedObjectContext) {
        // Get entity associated with "Pin" type
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Insert into context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Set properties
        latitude = NSNumber(double: latitudeDouble)
        longitude = NSNumber(double: longitudeDouble)
    }
    
    // Return the coordinate to conform to MKAnnotation Protocol
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
}
