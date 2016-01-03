import UIKit

class NewsItemTableViewCell: UITableViewCell {
    
    
    var newsItem: BubblaNews!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    
    @IBAction func facebookButtonClicked(sender: AnyObject) {
        if let facebookUrl = newsItem.facebookUrl {
            UIApplication.sharedApplication().openURL(NSURL(string: "https://www.facebook.com/nyhetsbubbla")!)
        }
    }
    
    @IBAction func twitterButtonClicked(sender: AnyObject) {
        if let twitterUrl = newsItem.twitterUrl {
            UIApplication.sharedApplication().openURL(twitterUrl)
        }
    }
    
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
}
