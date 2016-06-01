//
//  FlickrConstants.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: - Constants
    struct Constants {        
        // MARK - URLS
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest/?"
    }
    
    // MARK: - Flickr Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Accuracy = "accuracy"
        static let Latitude = "lat"
        static let Longitude = "lon"
    }
    
    // MARK: Flickr Parameter Values
    struct ParameterValues {
        static let APIKey = "cc549e4b35ec11bea908dcfdefff86bd"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 == "yes" */
        static let SmallURL = "url_s"
        static let SearchPhotosMethod = "flickr.photos.search"

    }
    
    // MARK: - JSON Keys
    struct JSONKeys {
        static let Photos = "photos"
        static let Pages = "pages"
        static let Photo = "photo"
        static let Stat = "stat"
        static let SmallURL = "url_s"
    }
}