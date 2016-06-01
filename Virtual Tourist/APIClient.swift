//
//  APIClient.swift
//  Virtual Tourist
//
//  Created by Patrick Montalto on 5/31/16.
//  Copyright © 2016 swift. All rights reserved.
//

import Foundation

class APIClient {
    
    // MARK: - Properties
    var session = NSURLSession.sharedSession()
    
    // MARK: - Create Request
    func buildRequestWithHTTPMethod(HTTPMethod: String, parameters: [String:AnyObject]?) -> NSURLRequest? {
        
        /* 1. Set the parameters so they can be appended to if necessary */
        let methodParameters = parameters
        
        /* GUARD: Is there a URL from the parameters? */
        guard let url = FlickrURLFromParameters(methodParameters) else {
            return nil
        }
        /* 2. Build the URL, Configure the request */
        var request = NSMutableURLRequest(URL: url)
        
        /* 3. Build the method */
        request.HTTPMethod = HTTPMethod
        
        return request
    }
    
    // MARK: - Create Task
    func taskForRequest(request: NSURLRequest, completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 4. Make the task from request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // MARK: - Error reporting function
            func sendError(error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForRequest", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request:\(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx")
                return
            }
            
            /* GUARD: Was there any data returned ? */
            guard var data = data else {
                sendError("No data returned!")
                return
            }
            
            /* 5. Parse the data and use the data (in the completion handler) */
            self.parseDataWithCompletionHandler(data, completionHandlerForParsedData: completionHandlerForGET)
        }
        /* 6. Start the request */
        task.resume()
        
        return task
    }

    // MARK: Helpers
    
    // create a URL from parameters
    private func FlickrURLFromParameters(parameters: [String:AnyObject]?) -> NSURL? {
        // check for UdacityClient type
        
        var urlString = "\(FlickrClient.Constants.ApiScheme)://\(FlickrClient.Constants.ApiHost)\(FlickrClient.Constants.ApiPath)"
        
        // Add parameters if present
        if let parameters = parameters {
            for (key, value) in parameters {
                urlString.appendContentsOf("&\(key)=\(value)")
            }
        }
        // TODO: Debugging
        print(urlString)
        
        return NSURL(string: urlString)
    
    }
    
    private func parseDataWithCompletionHandler(data: NSData, completionHandlerForParsedData: (result: AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult: AnyObject!
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            // Display error
            let userInfo = [NSLocalizedDescriptionKey: "Could not parse data as JSON: \(data)."]
            completionHandlerForParsedData(result: parsedResult, error: NSError(domain: "parseDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForParsedData(result: parsedResult, error: nil)
    }


}