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

extension NSDate {
    
    func isSameDayAsDate(date: NSDate) -> Bool {
        let dateCalendarComponents = NSCalendar.currentCalendar().components([.Era, .Year, .Month, .Day, .Hour, .Minute], fromDate: date)
        let calendarComponents = NSCalendar.currentCalendar().components([.Era, .Year, .Month, .Day, .Hour, .Minute], fromDate: self)
        return dateCalendarComponents.year == calendarComponents.year
            && dateCalendarComponents.month == calendarComponents.month
            && dateCalendarComponents.day == calendarComponents.day
    }
    
    var isToday: Bool {
        return isSameDayAsDate(NSDate())
    }
    
    
    var isTomorrow: Bool {
        return isSameDayAsDate(NSDate().dateByAddingTimeInterval(60*60*24))
    }
    
    var isYesterDay: Bool {
        return isSameDayAsDate(NSDate().dateByAddingTimeInterval(-60*60*24))
    }
    
    func format(format: String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.timeZone = NSTimeZone.systemTimeZone()
        dateFormatter.dateFormat = format
        dateFormatter.locale = NSLocale(localeIdentifier: "sv")
        return dateFormatter.stringFromDate(self)
    }
    
    var readableString: String {
        let time = self.format("HH:mm")
        
        if self.isToday {
            return "Idag \(time)"
        } else if self.isTomorrow {
            return "Imorgon \(time)"
        } else if self.isYesterDay {
            return "Igår \(time)"
        }
        
        let day = Int(self.format("dd"))!
        let month = self.format("MMMM")
        let year = self.format("yyyy")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "sv")
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        
        if year == NSDate().format("yyyy") {
            return "\(day) \(month) \(time)"
        } else {
            //            return "\(day) \(month) \(time), \(year)"
            return "\(day) \(month) \(year)"
        }
        
    }
}

extension UIViewController {
    func showErrorAlert(error: ErrorType) {
        let errorMessage = (error as NSError).localizedDescription
        let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .Default) {
            action in
            alertController.dismissViewControllerAnimated(true, completion: nil)
            })
        presentViewController(alertController, animated: true, completion: nil)
    }
    
}

extension UIView {
    
    
    func startActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.center = center
        activityIndicator.startAnimating()
        addSubview(activityIndicator)
        activityIndicator.didMoveToSuperview()
        activityIndicator.tag = 1337
        self.addConstraints([
            NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0),
            ])
    }
    
    func stopActivityIndicator() {
        for subview in subviews {
            if let activityIndicator = subview as? UIActivityIndicatorView {
                if activityIndicator.tag == 1337 {
                    activityIndicator.stopAnimating()
                    activityIndicator.removeFromSuperview()
                }
            }
        }
    }
}

extension UITableViewController {
    
    func showEmptyMessage(show: Bool, message: String) {
        if show {
            let label = UILabel(frame: CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height))
            label.font = UIFont.systemFontOfSize(30)
            label.text = message
            label.numberOfLines = 2
            label.textAlignment = .Center
            label.sizeToFit()
            label.textColor = UIColor.lightGrayColor()
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
        }
    }
    
    func deselectSelectedCell() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
}