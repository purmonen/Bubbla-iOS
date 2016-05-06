import UIKit
import SafariServices

class NewsItemTableViewCell: UITableViewCell {
    
    static var imageForNewsItem = [BubblaNews: UIImage]()
    static var bubblaNewsWithFailedImages = Set<BubblaNews>()
    
    
    weak var newsTableViewController: NewsTableViewController? = nil
    
    enum Appearance: String {
        case Image = "NewsItemTableViewCellImage"
        case FacebookLink = "NewsItemTableViewCellFacebookLink"
        case Domain = "NewsItemTableViewCellDomain"
        case TimeAndCategory = "NewsItemTableViewCellTimeAndCategory"
        
        var hidden: Bool {
            get { return NSUserDefaults.standardUserDefaults()[rawValue] as? Bool ?? false }
            set { NSUserDefaults.standardUserDefaults()[rawValue] = newValue }
        }
        
        var title: String {
            switch self {
            case Image: return "Bild"
            case FacebookLink: return "Facebooklänk"
            case Domain: return "Domän"
            case .TimeAndCategory: return "Tid och kategori"
            }
        }
        
        static var All = [Image, FacebookLink, Domain, TimeAndCategory]
        
    }
    
    var newsItem: BubblaNews! {
        didSet {
            facebookButton.hidden = newsItem.facebookUrl == nil || Appearance.FacebookLink.hidden
            titleLabel.text = newsItem.title
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd MMMM, HH:mm"
//            publicationDateLabel.text = dateFormatter.stringFromDate(newsItem.publicationDate).capitalizedString
            publicationDateLabel.text = newsItem.publicationDate.readableString + " · \(newsItem.category)"
            publicationDateLabel.hidden = Appearance.TimeAndCategory.hidden
            urlLabel.text = newsItem.domain
            urlLabel.hidden = Appearance.Domain.hidden
            unreadIndicator.hidden = newsItem.isRead
            
            unreadIndicator.textColor = UIApplication.sharedApplication().windows.first?.tintColor
            newsImageView.image = nil
            newsImageView.hidden = newsItem.imageUrl == nil
//            facebookButton.tag = indexPath.row
//            facebookButton.addTarget(self, action: "facebookButtonClicked:", forControlEvents: .TouchUpInside)
            
            
            if let imageUrl = newsItem.imageUrl where !NewsItemTableViewCell.bubblaNewsWithFailedImages.contains(newsItem) && !Appearance.Image.hidden {
                if let image = NewsItemTableViewCell.imageForNewsItem[newsItem] {
                    newsImageView.image = image
                } else {
                    NSOperationQueue().addOperationWithBlock {
                        if let image = UIImage(data: NSURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: imageUrl))?.data ?? NSData()) {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.newsImageView.image = image
                                
                            }
                        } else {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                self.newsImageView.startActivityIndicator()
                                self.newsImageView.image = UIImage(named: "blank")
                            }
                            BubblaUrlService().imageFromUrl(imageUrl) { response in
                                NSOperationQueue.mainQueue().addOperationWithBlock {
                                    switch response {
                                    case .Success(let image):
//                                        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? NewsItemTableViewCell {
//                                            NewsItemTableViewCell.imageForNewsItem[newsItem] = image
                                            self.newsImageView.image = image
//                                        }
                                    case .Error:
                                        NewsItemTableViewCell.bubblaNewsWithFailedImages.insert(self.newsItem)
//                                        if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? NewsItemTableViewCell {
                                            self.newsImageView.hidden = true
//                                        }
                                    }
                                    self.newsImageView.stopActivityIndicator()
                                }
                            }
                        }
                    }
                }
            } else {
                self.newsImageView.hidden = true
            }
        }
    }
    
    @IBAction func facebookButtonClicked(sender: AnyObject) {
        newsTableViewController?.openUrl(newsItem.facebookUrl!, entersReaderIfAvailable: false)
    }

    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
}
