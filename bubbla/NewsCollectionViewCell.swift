//
//  NewsCollectionViewCell.swift
//  Bubbla
//
//  Created by Sami Purmonen on 19/05/16.
//  Copyright © 2016 Sami Purmonen. All rights reserved.
//

import UIKit

class NewsCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    
    @IBOutlet weak var facebookButton: UIButton!
    @IBOutlet weak var twitterButton: UIButton!
    @IBOutlet weak var radioButton: UIButton!
    @IBOutlet weak var publicationDateLabel: UILabel!
    
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    
    static let imageHeight: CGFloat = 150
    
    var newsItem: BubblaNews! {
        didSet {
            imageHeightConstraint.constant = newsItem.imageUrl == nil ? 0 : NewsCollectionViewCell.imageHeight
            facebookButton.hidden = newsItem.facebookUrl == nil || NewsItemTableViewCell.Appearance.SocialMedia.hidden
            twitterButton.alpha = newsItem.twitterUrl == nil || NewsItemTableViewCell.Appearance.SocialMedia.hidden ? 0 : 1
            radioButton.alpha = newsItem.radioUrl == nil || NewsItemTableViewCell.Appearance.SocialMedia.hidden ? 0 : 1
            
            
            let newsHasChanged = titleLabel.text != newsItem.title
            
            titleLabel.text = newsItem.title
            
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "dd MMMM, HH:mm"
            publicationDateLabel.text = newsItem.publicationDate.readableString + " · \(newsItem.category)"
            publicationDateLabel.hidden = NewsItemTableViewCell.Appearance.TimeAndCategory.hidden
            urlLabel.text = newsItem.domain
            urlLabel.hidden = NewsItemTableViewCell.Appearance.Domain.hidden
//            unreadIndicator.hidden = newsItem.isRead
            
//            unreadIndicator.textColor = UIApplication.sharedApplication().windows.first?.tintColor
            
            if newsHasChanged {
                newsImageView.image = nil
            }
            newsImageView.hidden = newsItem.imageUrl == nil
            
            if let imageUrl = newsItem.imageUrl where !NewsItemTableViewCell.bubblaNewsWithFailedImages.contains(newsItem) && !NewsItemTableViewCell.Appearance.Image.hidden {
                if let image = NewsItemTableViewCell.imageForNewsItem[newsItem] {
                    newsImageView.image = image
                } else {
                    NSOperationQueue().addOperationWithBlock {
                        if let image = UIImage(data: NSURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: imageUrl))?.data ?? NSData()) {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                if self.newsItem.imageUrl == imageUrl {
                                    self.newsImageView.image = image
                                }
                                
                            }
                        } else {
                            NSOperationQueue.mainQueue().addOperationWithBlock {
                                if self.newsItem.imageUrl == imageUrl {
                                    self.newsImageView.startActivityIndicator()
                                    self.newsImageView.image = UIImage(named: "blank")
                                }
                            }
                            BubblaUrlService().imageFromUrl(imageUrl) { response in
                                NSOperationQueue.mainQueue().addOperationWithBlock {
                                    switch response {
                                    case .Success(let image):
                                        if self.newsItem.imageUrl == imageUrl {
                                            self.newsImageView.image = image
                                        }
                                    case .Error:
                                        NewsItemTableViewCell.bubblaNewsWithFailedImages.insert(self.newsItem)
                                        if self.newsItem.imageUrl == imageUrl {
                                            self.newsImageView.hidden = true
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
                self.newsImageView.hidden = true
            }
        }
    }
    
}
