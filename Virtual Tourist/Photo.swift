//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/27/16.
//  Copyright © 2016 swift. All rights reserved.
//

import UIKit
import CoreData

class Photo: NSManagedObject {
    struct Keys {
        static let ImagePath = "imagePath"
    }
    
    // MARK: Core Data Attributes
    @NSManaged var imagePath: String?
    @NSManaged var pinnedLocation: Pin?
    
    // MARK: Standard Core Data Init Method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: Two Argument Init Method
    init(imagePath: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.imagePath = imagePath
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath!)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath!)
        }
    }
}