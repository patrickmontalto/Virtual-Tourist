//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/27/16.
//  Copyright © 2016 swift. All rights reserved.
//

import CoreData

class Pin: NSManagedObject {
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
    }
    
    // MARK: Core Data Attributes
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    // MARK: Standard Core Data Init Method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: Two argument Init Method
    init(dictionary: [String:AnyObject], context: NSManagedObjectContext) {
        // Get entity associated with "Pin" type
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Insert into context
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Set properties
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
}
