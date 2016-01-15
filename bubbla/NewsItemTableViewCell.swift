import UIKit
import SafariServices

class NewsItemTableViewCell: UITableViewCell {
    
    
    var newsItem: BubblaNews!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
}
