//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import Foundation
import UIKit

// MARK: - FlickrClient: NSObject

class FlickrClient: NSObject {
    
    // MARK: - Singleton
    static let sharedInstance = FlickrClient()
    
    // TODO: - Get X Photos for location (Pin)
    func getPhotosForLocation(location: Pin, completionHandler: (success: Bool, photos: [[String:AnyObject]]?, errorString: String?) -> Void) {
        // Set accuracy to "City"
        let accuracy = 11
        
        // Set per page to 21 pictures
        let perPage = 21
        
        // Need to get a different page every time after finding out how many pages there are
        var page: Int {
            if let maxPage = location.maxPage as? Int {
                return min(Int(arc4random_uniform(UInt32(maxPage))) + 1, 99)
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
            completionHandler(success: false, photos: nil, errorString: "The request could not be processed")
            return
        }
        
        // GET Photos
        APIClient().taskForRequest(request) { (results, error) in
            /* Check for error */
            guard error == nil else {
                completionHandler(success: false, photos: nil, errorString: "An error occurred getting photos.")
                return
            }
            
            /* Check for photos dictionary */
            guard let photosDictionary = results[JSONKeys.Photos] as? [String:AnyObject] else {
                completionHandler(success: false, photos: nil, errorString: "Error: photos dictionary not found in result.")
                return
            }
            
            // Check total number of pages and set for current location
            if let totalPages = photosDictionary[JSONKeys.Pages] as? Int {
                location.maxPage = NSNumber(integer: totalPages)
                // Save context
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
            /* Check for photos array of dictionaries */
            guard let photoArray = photosDictionary[JSONKeys.Photo] as? [[String:AnyObject]] else {
                completionHandler(success: false, photos: nil, errorString: "Error: photo array not found in photos dictionary.")
                return
            }
            
            // Success case: return photoArray
            completionHandler(success: true, photos: photoArray, errorString: nil)
        }
    }
    
    
    // MARK: - Get Image data from file path
    func  getImageFromFilePath(urlString: String, completionHandler: (image: UIImage?, errorString: String?) -> Void)  {
        if let url = NSURL(string: urlString),
            let data = NSData(contentsOfURL: url),
            let image = UIImage(data: data){
            
            // Post notification when image finishes downloading.
            sendNotification("imageDidFinishDownloading")
            
            completionHandler(image: image, errorString: nil)
            
        } else {
            
            completionHandler(image: nil, errorString: "Error downloading image from url")
        }
    }
    
    private func sendNotification(notificationName: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(notificationName, object: nil)
    }
}









