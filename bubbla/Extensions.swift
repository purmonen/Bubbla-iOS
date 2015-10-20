import UIKit
import SWXMLHash

public func <(x: NSDate, y: NSDate) -> Bool { return x.timeIntervalSince1970 < y.timeIntervalSince1970 }
public func ==(x: NSDate, y: NSDate) -> Bool { return x.timeIntervalSince1970 == y.timeIntervalSince1970 }

extension NSURL {
    func data(callback: Response<NSData> -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: self)
        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            if let data = data {
                callback(.Success(data))
            } else if let error = error {
                callback(.Error(error))
            } else {
                callback(.Error(NSError(domain: "getData", code: 1337, userInfo: nil)))
            }
        }
        dataTask.resume()
    }
    
    func xml(callback: Response<XMLIndexer> -> Void) {
        data() {
            callback($0.map { SWXMLHash.parse($0) } )
        }
    }
}

extension NSUserDefaults {
    subscript(key: String) -> AnyObject? {
        get { return valueForKey(key) }
        set { setValue(newValue, forKey: key) }
    }
}