//
//  NewsCollectionViewController.swift
//  Bubbla
//
//  Created by Sami Purmonen on 19/05/16.
//  Copyright © 2016 Sami Purmonen. All rights reserved.
//

import UIKit
import SafariServices

private let reuseIdentifier = "NewsCollectionViewCell"

class NewsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    
    var newsItems = [BubblaNews]()
    
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

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.registerClass(NewsCollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        // Do any additional setup after loading the view.
    }
    
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let width = UIScreen.mainScreen().bounds.size.width / 2.0
//        let newsItem = newsItems[indexPath.row]
        
        
//        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! NewsCollectionViewCell
//
//        
//        cell.titleLabel.text = newsItem.title
//        let titleHeight = cell.titleLabel.sizeThatFits(CGSize(width: width, height: 1000000.0)).height
//        let imageHeight = cell.newsImageView.bounds.height
        return CGSize.zero
//        return CGSize(width: width, height: cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height)
    }
    
    func openUrl(url: NSURL, entersReaderIfAvailable: Bool) {
    
        presentViewController(safariViewControllerForUrl(url, entersReaderIfAvailable: entersReaderIfAvailable), animated: true, completion: nil)
    }
    
    func safariViewControllerForUrl(url: NSURL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(URL: url, entersReaderIfAvailable: entersReaderIfAvailable)
//        viewController.delegate = self
        viewController.view.tintColor = UIApplication.sharedApplication().windows.first?.tintColor
        return viewController
    }
    
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        openUrl(newsItems[indexPath.row].url, entersReaderIfAvailable: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return newsItems.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! NewsCollectionViewCell
        cell.newsItem = newsItems[indexPath.row]
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(collectionView: UICollectionView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func collectionView(collectionView: UICollectionView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */

}
