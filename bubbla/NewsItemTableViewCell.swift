import UIKit
import SafariServices
import AVFoundation
import AVKit

class NewsItemTableViewCell: UITableViewCell {
    
    static var imageForNewsItem = [BubblaNews: UIImage]()
    static var bubblaNewsWithFailedImages = Set<BubblaNews>()
    weak var newsTableViewController: NewsTableViewController? = nil
    
    enum Appearance: String {
        case Image = "NewsItemTableViewCellImage"
        case Domain = "NewsItemTableViewCellDomain"
        case TimeAndCategory = "NewsItemTableViewCellTimeAndCategory"
        case SocialMedia = "NewsItemTableViewCellSocialMedia"
        
        var hidden: Bool {
            get { return UserDefaults.standard[rawValue] as? Bool ?? false }
            set { UserDefaults.standard[rawValue] = newValue as AnyObject? }
        }
        
        var title: String {
            switch self {
            case .Image: return NSLocalizedString("Image", comment: "")
            case .Domain: return NSLocalizedString("Domain", comment: "")
            case .TimeAndCategory: return NSLocalizedString("Time and category", comment: "")
            case .SocialMedia: return NSLocalizedString("Social media", comment: "")
            }
        }
        
        static var All = [Image, SocialMedia, Domain, TimeAndCategory]
    }
    
    var newsItem: BubblaNews! {
        didSet {
            facebookButton.isHidden = newsItem.facebookUrl == nil || Appearance.SocialMedia.hidden
            twitterButton.alpha = newsItem.twitterUrl == nil || Appearance.SocialMedia.hidden ? 0 : 1
            radioButton.alpha = newsItem.radioUrl == nil || Appearance.SocialMedia.hidden ? 0 : 1
            
            
            let newsHasChanged = titleLabel.text != newsItem.title
            
            titleLabel.text = newsItem.title
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMMM, HH:mm"
            publicationDateLabel.text = newsItem.publicationDate.readableString + " · \(newsItem.category)"
            publicationDateLabel.isHidden = Appearance.TimeAndCategory.hidden
            urlLabel.text = newsItem.domain
            urlLabel.isHidden = Appearance.Domain.hidden
            unreadIndicator.isHidden = newsItem.isRead
            
            unreadIndicator.textColor = UIApplication.shared.windows.first?.tintColor
            
            if newsHasChanged {
                newsImageView.image = nil
            }
            newsImageView.isHidden = newsItem.imageUrl == nil
            
            if let imageUrl = newsItem.imageUrl, !NewsItemTableViewCell.bubblaNewsWithFailedImages.contains(newsItem) && !Appearance.Image.hidden {
                if let image = NewsItemTableViewCell.imageForNewsItem[newsItem] {
                    newsImageView.image = image
                } else {
                    OperationQueue().addOperation {
                        if let image = UIImage(data: URLCache.shared.cachedResponse(for: URLRequest(url: imageUrl as URL))?.data ?? Data()) {
                            OperationQueue.main.addOperation {
                                if self.newsItem.imageUrl == imageUrl {
                                    self.newsImageView.image = image
                                }
                                
                            }
                        } else {
                            OperationQueue.main.addOperation {
                                if self.newsItem.imageUrl == imageUrl {
                                    self.newsImageView.startActivityIndicator()
                                    self.newsImageView.image = UIImage(named: "blank")
                                }
                            }
                            BubblaUrlService().imageFromUrl(imageUrl) { response in
                                OperationQueue.main.addOperation {
                                    switch response {
                                    case .success(let image):
                                        if self.newsItem.imageUrl == imageUrl {
                                            self.newsImageView.image = image
                                        }
                                    case .error:
                                        NewsItemTableViewCell.bubblaNewsWithFailedImages.insert(self.newsItem)
                                        if self.newsItem.imageUrl == imageUrl {
                                            self.newsImageView.isHidden = true
                                        }
                                    }
                                    if self.newsItem.imageUrl == imageUrl {
                                        self.newsImageView.stopActivityIndicator()
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                self.newsImageView.isHidden = true
            }
        }
    }
    
    var player: AVPlayer?
    
    @IBAction func facebookButtonClicked(_ sender: AnyObject) {
        if let facebookUrl = newsItem.facebookUrl {
            newsTableViewController?.openUrl(facebookUrl, entersReaderIfAvailable: false)
        }
    }

    @IBAction func twitterButtonClicked(_ sender: AnyObject) {
        if let twitterUrl = newsItem.twitterUrl {
            newsTableViewController?.openUrl(twitterUrl, entersReaderIfAvailable: false)
        }
    }
    @IBAction func radioLinkClicked(_ sender: AnyObject) {
        if let radioUrl = newsItem.radioUrl {
            newsTableViewController?.openUrl(radioUrl, entersReaderIfAvailable: false)
        }
    }
    @IBOutlet weak var socialMediaStackView: UIStackView!
    
    @IBOutlet weak var radioButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var publicationDateLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var unreadIndicator: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
}
