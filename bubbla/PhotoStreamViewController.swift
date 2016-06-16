//
//  PhotoStreamViewController.swift
//  RWDevCon
//
//  Created by Mic Pringle on 26/02/2015.
//  Copyright (c) 2015 Ray Wenderlich. All rights reserved.
//

import UIKit
import AVFoundation
import SafariServices

class PhotoStreamViewController: UICollectionViewController {
  
  var newsItems = [BubblaNews]()
  
  override func preferredStatusBarStyle() -> UIStatusBarStyle {
    return UIStatusBarStyle.LightContent
  }

    
    /*
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if let layout = collectionView?.collectionViewLayout as? PinterestLayout {
            layout.setSizes()
            layout.prepareLayout()
            
        }
    }
 */
    
    
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    BubblaApi.newsForCategory(nil) {
        switch $0 {
        case .Success(let newsItems):
            NSOperationQueue.mainQueue().addOperationWithBlock {
                self.newsItems = newsItems
                self.collectionView?.reloadData()
            }
        case .Error(let error):
            print(error)
        }
    }
    
    if let layout = collectionView?.collectionViewLayout as? PinterestLayout {
      layout.delegate = self
    }

  }
  
}

extension PhotoStreamViewController: SFSafariViewControllerDelegate {
    
}

extension PhotoStreamViewController {
    
    func safariViewControllerForUrl(url: NSURL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(URL: url, entersReaderIfAvailable: entersReaderIfAvailable)
        viewController.delegate = self
        viewController.view.tintColor = UIApplication.sharedApplication().windows.first?.tintColor
        return viewController
    }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return newsItems.count
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("NewsCollectionViewCell", forIndexPath: indexPath) as! NewsCollectionViewCell
    cell.newsItem = newsItems[indexPath.item]
    return cell
  }
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let newsItem = newsItems[indexPath.item]
        presentViewController(safariViewControllerForUrl(newsItem.url, entersReaderIfAvailable: true), animated: true, completion: nil)
        
        
    }
    
    
  
}

extension PhotoStreamViewController : PinterestLayoutDelegate {
  // 1. Returns the photo height
  func collectionView(collectionView:UICollectionView, heightForPhotoAtIndexPath indexPath:NSIndexPath , withWidth width:CGFloat) -> CGFloat {
    let newsItem = newsItems[indexPath.item]
    return newsItem.imageUrl == nil ? 0 : NewsCollectionViewCell.imageHeight
    
  }
  
    
    func heightForComment(comment: String, font: UIFont, width: CGFloat) -> CGFloat {
        let rect = NSString(string: comment).boundingRectWithSize(CGSize(width: width, height: CGFloat(MAXFLOAT)), options: .UsesLineFragmentOrigin, attributes: [NSFontAttributeName: font], context: nil)
        return ceil(rect.height)
    }

    
  // 2. Returns the annotation size based on the text
  func collectionView(collectionView: UICollectionView, heightForAnnotationAtIndexPath indexPath: NSIndexPath, withWidth width: CGFloat) -> CGFloat {
    let newsItem = newsItems[indexPath.item]
    let stackViewPadding = CGFloat((4+(newsItem.facebookUrl == nil ? 0 : 1)+(newsItem.imageUrl == nil ? 0 : 1))*3)
    let socialImagesHeight = CGFloat(newsItem.facebookUrl == nil ? 0 : 35)
    let otherInformationHeight = CGFloat(15*2)
    
    
    let font = UIFont.systemFontOfSize(20)
    let titleHeight = heightForComment(newsItem.title, font: font, width: width)
    let height = stackViewPadding + otherInformationHeight + socialImagesHeight + titleHeight
    return height
  }
}

