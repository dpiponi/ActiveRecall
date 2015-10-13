//
//  Downloader.swift
//  MasterDetail1
//

import Foundation

//
// http://stackoverflow.com/questions/28219848/download-file-in-swift
//
class Downloader {
    class func load(filename:String, URL: NSURL) {
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: sessionConfig, delegate: nil, delegateQueue: nil)
        let request = NSMutableURLRequest(URL: URL)
        request.HTTPMethod = "GET"
        let task = session.dataTaskWithRequest(request, completionHandler: { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            if (error == nil) {
                // Success
                let statusCode = (response as! NSHTTPURLResponse).statusCode
                print("Success: \(statusCode)")
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
                print("downloader:", documentsPath)
                
                
                let fullFileName = documentsPath.stringByAppendingPathComponent(filename)
                print("fullfilename =", fullFileName)
                
                data?.writeToFile(fullFileName, atomically: true)
            }
            else {
                // Failure
                print("Failure: %@", error?.localizedDescription);
            }
        })
        task.resume()
    }
}