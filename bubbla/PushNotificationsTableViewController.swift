
import UIKit


var disallowPushNotificationsForCategories: [String] {
get {
    return UserDefaults.standard["disallowPushNotificationsForCategories"] as? [String] ?? []
}

set {
    UserDefaults.standard["disallowPushNotificationsForCategories"] = newValue
}
}

class PushNotificationsTableViewController: UITableViewController {
    
    var categories = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.showEmptyMessage(categories.isEmpty, message: "Inga kategorier")
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let deviceToken = DeviceToken {
            BubblaApi.registerDevice(deviceToken, excludeCategories: disallowPushNotificationsForCategories) {
                print($0)
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationTableViewCell", for: indexPath) as! PushNotificationTableViewCell
        
        let category = categories[indexPath.row]
        cell.categoryLabel.text = category
        cell.allowPushNotificationsSwitch.isOn = !disallowPushNotificationsForCategories.contains(category)
        cell.allowPushNotificationsSwitch.addTarget(self, action: "switchChanged:", for: .valueChanged)
        cell.allowPushNotificationsSwitch.tag = indexPath.row
        
        return cell
    }
    
    func switchChanged(_ sender: UISwitch) {
        print("SWITCH CHAGNED! \(sender.tag)")
        let category = categories[sender.tag]
        
        if sender.isOn {
            disallowPushNotificationsForCategories = disallowPushNotificationsForCategories.filter { $0 != category }
        } else {
            if !disallowPushNotificationsForCategories.contains(category) {
                disallowPushNotificationsForCategories.append(category)
            }
        }
        
        print("Should update: \(DeviceToken)")
    }
    
    
}
