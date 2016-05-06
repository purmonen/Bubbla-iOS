import UIKit

class NewsAppearenceTableViewController: UITableViewController {
    
    
    var newsItem: BubblaNews? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BubblaApi.newsForCategory(nil) { response in
            switch response {
            case .Success(let news):
                if let newsItem = news.filter({ $0.imageUrl != nil && $0.facebookUrl != nil }).first {
                    self.newsItem = newsItem
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.tableView.reloadData()
                    }
                }
            case .Error(let error):
                break
            }
        }
        //        newsImageSwitch.on = NewsItemTableViewCell.showImage
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return 1
        } else {
            return NewsItemTableViewCell.Appearance.All.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCellWithIdentifier("NewsItemTableViewCell") as! NewsItemTableViewCell
            if let newsItem = newsItem {
                cell.newsItem = newsItem
            }
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("PushNotificationTableViewCell") as! PushNotificationTableViewCell
            let appearance = NewsItemTableViewCell.Appearance.All[indexPath.row]
            cell.allowPushNotificationsSwitch.on = !appearance.hidden
            cell.allowPushNotificationsSwitch.addTarget(self, action: Selector("appearanceChanged:"), forControlEvents: .ValueChanged)
            cell.allowPushNotificationsSwitch.tag = indexPath.row
            cell.categoryLabel.text = appearance.title
            
            return cell
        }
        
    }
    
    
    func appearanceChanged(sender: UISwitch) {
        NewsItemTableViewCell.Appearance.All[sender.tag].hidden = !sender.on
        tableView.reloadData()
    }
}
