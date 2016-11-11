import UIKit



extension UITableView {
    func updateFromItems<T: Equatable>(_ items: [T], oldItems: [T]) {
        self.beginUpdates()
        let newItems = items.filter { !oldItems.contains($0) }
        let newIndexPaths = newItems.map { return IndexPath(row: items.index(of: $0)!, section: 0)  }
        let removedItems = oldItems.filter { !items.contains($0) }
        let removedIndexPaths = removedItems.map { return IndexPath(row: oldItems.index(of: $0)!, section: 0)  }
        let persistentItems = items.filter { !newItems.contains($0) && !removedItems.contains($0)  }
        for item in persistentItems {
            let startIndex = oldItems.index(of: item)!
            let endIndex = items.index(of: item)!
            if startIndex != endIndex {
                self.moveRow(at: IndexPath(row: startIndex, section: 0), to: IndexPath(row: endIndex, section: 0))
            }
        }
        self.insertRows(at: newIndexPaths, with: .automatic)
        self.deleteRows(at: removedIndexPaths, with: .automatic)
        self.endUpdates()
    }
}

extension UserDefaults {
    subscript(key: String) -> AnyObject? {
        get { return value(forKey: key) as AnyObject? }
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

extension Date {
    
    func isSameDayAsDate(_ date: Date) -> Bool {
        let dateCalendarComponents = (Calendar.current as NSCalendar).components([.era, .year, .month, .day, .hour, .minute], from: date)
        let calendarComponents = (Calendar.current as NSCalendar).components([.era, .year, .month, .day, .hour, .minute], from: self)
        return dateCalendarComponents.year == calendarComponents.year
            && dateCalendarComponents.month == calendarComponents.month
            && dateCalendarComponents.day == calendarComponents.day
    }
    
    var isToday: Bool {
        return isSameDayAsDate(Date())
    }
    
    
    var isTomorrow: Bool {
        return isSameDayAsDate(Date().addingTimeInterval(60*60*24))
    }
    
    var isYesterDay: Bool {
        return isSameDayAsDate(Date().addingTimeInterval(-60*60*24))
    }
    
    func format(_ format: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
    
    var readableString: String {
        let time = self.format("HH:mm")
        
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
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = DateFormatter.Style.short
        
        if year == Date().format("yyyy") {
            return "\(day) \(month) \(time)"
        } else {
            //            return "\(day) \(month) \(time), \(year)"
            return "\(day) \(month) \(year)"
        }
        
    }
}

extension UIViewController {
    func showErrorAlert(_ error: Error) {
        let errorMessage = (error as NSError).localizedDescription
        let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default) {
            action in
            alertController.dismiss(animated: true, completion: nil)
            })
        present(alertController, animated: true, completion: nil)
    }
}

extension UIView {
    
    func showMessageLabel(_ message: String) {
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 30)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        
        label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        label.widthAnchor.constraint(equalTo: widthAnchor, constant: -100).isActive = true
    }
    
    func startActivityIndicator() {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        activityIndicator.frame = frame
        addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        centerXAnchor.constraint(equalTo: activityIndicator.centerXAnchor).isActive = true
        centerYAnchor.constraint(equalTo: activityIndicator.centerYAnchor).isActive = true
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
    
    func showEmptyMessage(_ show: Bool, message: String) {
        if show {
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.bounds.size.width, height: view.bounds.size.height))
            label.font = UIFont.systemFont(ofSize: 30)
            label.text = message
            label.numberOfLines = 0
            label.textAlignment = .center
            label.sizeToFit()
            label.textColor = UIColor.lightGray
            tableView.backgroundView = label
            tableView.separatorStyle = UITableViewCellSeparatorStyle.none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
        }
    }
    
    func deselectSelectedCell() {
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
}
