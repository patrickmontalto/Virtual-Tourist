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
 
    // MARK: Core Data Attributes
    @NSManaged var url: String
    @NSManaged var filePath: String?
    @NSManaged var pinnedLocation: Pin?
    
    // MARK: Standard Core Data Init Method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // MARK: Two Argument Init Method
    init(pin: Pin, photoURL: String, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.url = photoURL
        self.pinnedLocation = pin
    }
    
    var image: UIImage? {
        if let filePath = filePath {
            
            if filePath == "error" {
                return UIImage(named: "noImage")
            }
            
            let fileName = NSString(string: filePath).lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] 
            let pathComponents = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathComponents)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        return nil
    }
}