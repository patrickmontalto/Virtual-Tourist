//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import Foundation
import UIKit
import CoreData 

// MARK: - FlickrClient: NSObject

class FlickrClient: NSObject {
    
    // MARK: - Singleton
    static let sharedInstance = FlickrClient()
    
    // Get Photos for location (Pin)
    func getPhotosForLocation(location: Pin, completionHandler: (success: Bool, errorString: String?) -> Void) {
        // Set accuracy to "City"
        let accuracy = 11
        
        // Set per page to 21 pictures
        let perPage = 21
        
        // Need to get a different page every time after finding out how many pages there are
        var page: Int {
            if let maxPage = location.maxPage as? Int {
                return min(Int(arc4random_uniform(UInt32(maxPage))) + 1, 20)
            } else {
                return 1
            }
        }
        
        // Build method parameters
        let parameters: [String:AnyObject] = [
            ParameterKeys.APIKey:ParameterValues.APIKey,
            ParameterKeys.Method:ParameterValues.SearchPhotosMethod,
            ParameterKeys.Accuracy: accuracy,
            ParameterKeys.Latitude: location.latitude,
            ParameterKeys.Longitude: location.longitude,
            ParameterKeys.Extras: ParameterValues.SmallURL,
            ParameterKeys.PerPage: perPage,
            ParameterKeys.Page:page,
            ParameterKeys.Format:ParameterValues.ResponseFormat,
            ParameterKeys.NoJSONCallback:ParameterValues.DisableJSONCallback
        ]
        
        // Build request
        guard let request = APIClient().buildRequestWithHTTPMethod(APIClient.HTTPMethods.GET, parameters: parameters) else {
            completionHandler(success: false, errorString: "The request could not be processed")
            return
        }
        
        // GET Photos
        APIClient().taskForRequest(request) { (results, error) in
            /* Check for error */
            guard error == nil else {
                completionHandler(success: false, errorString: "An error occurred getting photos.")
                return
            }
            
            /* Check for photos dictionary */
            guard let photosDictionary = results[JSONKeys.Photos] as? [String:AnyObject] else {
                completionHandler(success: false, errorString: "Error: photos dictionary not found in result.")
                return
            }
            
            // Check total number of pages and set for current location
            if let totalPages = photosDictionary[JSONKeys.Pages] as? Int {
                // The max page returned needs to be from 1 to the maxPage or 20, whichever is higher.
                location.maxPage = NSNumber(integer: min((totalPages), 20))
            }
            
            /* Check for photos array of dictionaries */
            guard let photoArray = photosDictionary[JSONKeys.Photo] as? [[String:AnyObject]] else {
                completionHandler(success: false, errorString: "Error: photo array not found in photos dictionary.")
                return
            }
            
            // Now we have an array of photo dictionaries. Create the photo and download the image for each
            for photo in photoArray {
                // Get URL of image
                let photoURLString = photo[JSONKeys.SmallURL] as! String
                
                // Create new Photo object
                let newPhoto = Photo(pin: location, photoURL: photoURLString, context: self.sharedContext)
                
                // Save context??
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                })
                
                // Download photo using URL
                self.getImageForPhoto(newPhoto, completionHandler: { (success, errorString) in
                })
                
            }
            CoreDataStackManager.sharedInstance().saveContext()
            completionHandler(success: true, errorString: nil)
        }
    }
    
    
    // MARK: - Get Image data from file path
    func  getImageForPhoto(photo: Photo, completionHandler: (success: Bool, errorString: String?) -> Void)  {
        let imageURLString = photo.url
        
        if let url = NSURL(string: imageURLString), let data = NSData(contentsOfURL: url) {
            
            // Get filename and file URL
            let fileName = NSString(string: imageURLString).lastPathComponent
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            let pathComponents = [dirPath, fileName]
            let fileURL = NSURL.fileURLWithPathComponents(pathComponents)!
            
            // Save File
            NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: data, attributes: nil)
            
            // Update Photo Model
            photo.filePath = fileURL.path!
            
            completionHandler(success: true, errorString: nil)
            
        } else {
            // Update Photo Model for error case
            photo.filePath = "error"
            
            completionHandler(success: false, errorString: "Error downloading image from url")
        }
    }
    
    // MARK: - Shared Context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
}









