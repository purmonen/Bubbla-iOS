
import UIKit


var disallowPushNotificationsForCategories: [String] {
get {
    return NSUserDefaults.standardUserDefaults()["disallowPushNotificationsForCategories"] as? [String] ?? []
}

set {
    NSUserDefaults.standardUserDefaults()["disallowPushNotificationsForCategories"] = newValue
}
}

class PushNotificationsTableViewController: UITableViewController {
    
    var categories = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showEmptyMessage(categories.isEmpty, message: "Inga kategorier")
    }
    
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let deviceToken = DeviceToken {
            BubblaApi.registerDevice(deviceToken, excludeCategories: disallowPushNotificationsForCategories) {
                print($0)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PushNotificationTableViewCell", forIndexPath: indexPath) as! PushNotificationTableViewCell
        
        let category = categories[indexPath.row]
        cell.categoryLabel.text = category
        cell.allowPushNotificationsSwitch.on = !disallowPushNotificationsForCategories.contains(category)
        cell.allowPushNotificationsSwitch.addTarget(self, action: "switchChanged:", forControlEvents: .ValueChanged)
        cell.allowPushNotificationsSwitch.tag = indexPath.row
        
        return cell
    }
    
    func switchChanged(sender: UISwitch) {
        print("SWITCH CHAGNED! \(sender.tag)")
        let category = categories[sender.tag]
        
        if sender.on {
            disallowPushNotificationsForCategories = disallowPushNotificationsForCategories.filter { $0 != category }
        } else {
            if !disallowPushNotificationsForCategories.contains(category) {
                disallowPushNotificationsForCategories.append(category)
            }
        }
        
        print("Should update: \(DeviceToken)")
    }
    
    
}
