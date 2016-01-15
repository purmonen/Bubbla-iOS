import UIKit
import SafariServices

class NewsItemTableViewCell: UITableViewCell {
    
    
    var newsItem: BubblaNews!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    
    @IBAction func facebookButtonClicked(sender: AnyObject) {
        if let facebookUrl = newsItem.facebookUrl,
            let postId = facebookUrl.absoluteString.componentsSeparatedByString("_").last {
//            UIApplication.sharedApplication().openURL(facebookUrl)
//            facebookUrl.absoluteString.split
//            UIApplication.sharedApplication().openURL(NSURL(string: "https://www.facebook.com/nyhetsbubbla/posts/504457646401499:0")!)
//                
//                let facebookPostUrl = NSURL(string: "https://www.facebook.com/nyhetsbubbla/posts/\(postId)")!
//                let safariViewController = SFSafariViewController(URL: facebookPostUrl)
//                presentViewController(safariViewController, animated: true, completion: nil)
//                if splitViewController!.collapsed {
//                    presentViewController(safariViewController, animated: true, completion: nil)
//                } else {
//                    splitViewController?.showDetailViewController(safariViewController, sender: self)
//                }
//                UIApplication.sharedApplication().openURL(NSURL(string: "https://www.facebook.com/nyhetsbubbla/posts/\(postId)")!)
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
