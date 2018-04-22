import UIKit


var disallowPushNotificationsForCategories: [String] {
get {
    return UserDefaults.standard["disallowPushNotificationsForCategories"] as? [String] ?? []
}

set {
    UserDefaults.standard["disallowPushNotificationsForCategories"] = newValue as AnyObject?
}
}

class PushNotificationsTableViewController: RefreshableTableViewController {

	var data = [_BubblaApi.Topic]() {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func load() {
		BubblaApi.listTopics() { response in
			OperationQueue.main.addOperation {
				switch response {
				case .success(let topics):
					self.data = topics
					self.successfulRefresh()
				case .error(let error):
					self.errorRefresh(error: error)
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationTableViewCell", for: indexPath) as! PushNotificationTableViewCell
        let category = data[indexPath.row]
        cell.categoryLabel.text = category.name.capitalized
        cell.allowPushNotificationsSwitch.isOn = !disallowPushNotificationsForCategories.contains(category.topicArn)
        cell.allowPushNotificationsSwitch.addTarget(self, action: #selector(PushNotificationsTableViewController.switchChanged(_:)), for: .valueChanged)
        cell.allowPushNotificationsSwitch.tag = indexPath.row
        return cell
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        let category = data[sender.tag]
        if sender.isOn {
            disallowPushNotificationsForCategories = disallowPushNotificationsForCategories.filter { $0 != category.topicArn }
        } else {
            if !disallowPushNotificationsForCategories.contains(category.topicArn) {
                disallowPushNotificationsForCategories.append(category.topicArn)
            }
        }
    }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}
}
