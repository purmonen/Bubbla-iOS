import UIKit

class NewsAppearenceTableViewController: UITableViewController {
    
    
    var newsItem: BubblaNews? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BubblaApi.news() { response in
            switch response {
            case .success(let news):
                if let newsItem = news.filter({ $0.imageUrl != nil && $0.facebookUrl != nil }).first {
                    self.newsItem = newsItem
                    OperationQueue.main.addOperation {
                        self.tableView.reloadData()
                    }
                }
            case .error(_):
                break
            }
        }
        //        newsImageSwitch.on = NewsItemTableViewCell.showImage
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1
        } else {
            return NewsItemTableViewCell.Appearance.All.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NewsItemTableViewCell") as! NewsItemTableViewCell
            if let newsItem = newsItem {
                cell.newsItem = newsItem
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "PushNotificationTableViewCell") as! PushNotificationTableViewCell
            let appearance = NewsItemTableViewCell.Appearance.All[indexPath.row]
            cell.allowPushNotificationsSwitch.isOn = !appearance.hidden
            cell.allowPushNotificationsSwitch.addTarget(self, action: #selector(NewsAppearenceTableViewController.appearanceChanged(_:)), for: .valueChanged)
            cell.allowPushNotificationsSwitch.tag = indexPath.row
            cell.categoryLabel.text = appearance.title
            
            return cell
        }
        
    }
    
    
    func appearanceChanged(_ sender: UISwitch) {
        NewsItemTableViewCell.Appearance.All[sender.tag].hidden = !sender.isOn
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }
}
