
import UIKit


var disallowPushNotificationsForCategories: [String] {
get {
    return UserDefaults.standard["disallowPushNotificationsForCategories"] as? [String] ?? []
}

set {
    UserDefaults.standard["disallowPushNotificationsForCategories"] = newValue as AnyObject?
}
}

class PushNotificationsTableViewController: UITableViewController {
    
    var categories = [_BubblaApi.Topic]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
		BubblaApi.listTopics() {
			switch $0 {
			case .success(let topics):
				OperationQueue.main.addOperation {
					self.categories = topics
					self.tableView.reloadData()
				}
			case .error(let error):
				if self.categories.isEmpty {
					self.showEmptyMessage(true, message: (error as NSError).localizedDescription)
				} else {
					print(error)
				}
			}
		}
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let deviceToken = DeviceToken {
            BubblaApi.registerDevice(deviceToken, excludeCategories: disallowPushNotificationsForCategories) {
                print($0)
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationTableViewCell", for: indexPath) as! PushNotificationTableViewCell
        let category = categories[indexPath.row]
        cell.categoryLabel.text = category.name.capitalized
        cell.allowPushNotificationsSwitch.isOn = !disallowPushNotificationsForCategories.contains(category.topicArn)
        cell.allowPushNotificationsSwitch.addTarget(self, action: #selector(PushNotificationsTableViewController.switchChanged(_:)), for: .valueChanged)
        cell.allowPushNotificationsSwitch.tag = indexPath.row
        return cell
    }
    
    func switchChanged(_ sender: UISwitch) {
        let category = categories[sender.tag]
        if sender.isOn {
            disallowPushNotificationsForCategories = disallowPushNotificationsForCategories.filter { $0 != category.topicArn }
        } else {
            if !disallowPushNotificationsForCategories.contains(category.topicArn) {
                disallowPushNotificationsForCategories.append(category.topicArn)
            }
        }
    }
}
