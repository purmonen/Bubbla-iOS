import UIKit

public func <(x: NSDate, y: NSDate) -> Bool { return x.timeIntervalSince1970 < y.timeIntervalSince1970 }
public func ==(x: NSDate, y: NSDate) -> Bool { return x.timeIntervalSince1970 == y.timeIntervalSince1970 }

extension UITableView {
    func updateFromItems<T: Equatable>(items: [T], oldItems: [T]) {
        self.beginUpdates()
        let newItems = items.filter { !oldItems.contains($0) }
        let newIndexPaths = newItems.map { return NSIndexPath(forRow: items.indexOf($0)!, inSection: 0)  }
        let removedItems = oldItems.filter { !items.contains($0) }
        let removedIndexPaths = removedItems.map { return NSIndexPath(forRow: oldItems.indexOf($0)!, inSection: 0)  }
        let persistentItems = items.filter { !newItems.contains($0) && !removedItems.contains($0)  }
        for item in persistentItems {
            let startIndex = oldItems.indexOf(item)!
            let endIndex = items.indexOf(item)!
            if startIndex != endIndex {
                self.moveRowAtIndexPath(NSIndexPath(forRow: startIndex, inSection: 0), toIndexPath: NSIndexPath(forRow: endIndex, inSection: 0))
            }
        }
        self.insertRowsAtIndexPaths(newIndexPaths, withRowAnimation: .Automatic)
        self.deleteRowsAtIndexPaths(removedIndexPaths, withRowAnimation: .Automatic)
        self.endUpdates()
    }
}

extension NSUserDefaults {
    subscript(key: String) -> AnyObject? {
        get { return valueForKey(key) }
        set { setValue(newValue, forKey: key) }
    }
}

extension UIColor {
    convenience init(hex: Int) {
        let red = CGFloat((hex >> 16) & 0xff) / 255.0
        let green = CGFloat((hex >> 8) & 0xff) / 255.0
        let blue = CGFloat(hex & 0xff) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
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
        
        let locale = NSLocale(localeIdentifier: "sv")
        
        if self.isToday {
            return "\(NSLocalizedString("Today", comment: "")) \(time)"
        } else if self.isTomorrow {
            return "\(NSLocalizedString("Tomorrow", comment: "")) \(time)"
        } else if self.isYesterDay {
            return "\(NSLocalizedString("Yesterday", comment: "")) \(time)"
        }
        
        let day = Int(self.format("dd"))!
        let month = self.format("MMMM")
        let year = self.format("yyyy")
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = locale
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
    
    func showMessageLabel(message: String) {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.font = UIFont.systemFontOfSize(30)
        label.textColor = UIColor.lightGrayColor()
        label.textAlignment = .Center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        
        label.centerYAnchor.constraintEqualToAnchor(centerYAnchor).active = true
        label.centerXAnchor.constraintEqualToAnchor(centerXAnchor).active = true
        label.widthAnchor.constraintEqualToAnchor(widthAnchor, constant: -100).active = true
    }
    
    func startActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityIndicator.frame = frame
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraintEqualToAnchor(activityIndicator.centerXAnchor).active = true
        centerYAnchor.constraintEqualToAnchor(activityIndicator.centerYAnchor).active = true
        activityIndicator.startAnimating()
        layoutIfNeeded()
        activityIndicator.tag = 1337
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
            label.numberOfLines = 0
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