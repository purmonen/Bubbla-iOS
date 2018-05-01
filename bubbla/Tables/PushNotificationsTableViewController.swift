import UIKit


class PushNotificationsTableViewController: RefreshableTableViewController {

	var data = [Topic]() {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func load() {
		BubblaApi.notificationService.listTopics() { response in
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
            BubblaApi.registerDevice(deviceToken, topicPreferences: UserDefaultsTopicPreferences) {
                print($0)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationTableViewCell", for: indexPath) as! PushNotificationTableViewCell
        let topic = data[indexPath.row]
        cell.categoryLabel.text = topic.name.capitalized
        cell.allowPushNotificationsSwitch.isOn = !UserDefaultsTopicPreferences.excludeTopic(topic)
        cell.allowPushNotificationsSwitch.addTarget(self, action: #selector(PushNotificationsTableViewController.switchChanged(_:)), for: .valueChanged)
        cell.allowPushNotificationsSwitch.tag = indexPath.row
        return cell
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        let topic = data[sender.tag]
		UserDefaultsTopicPreferences.makeTopic(topic, excluded: !sender.isOn)
    }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return data.count
	}
}
