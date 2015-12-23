import UIKit
import SafariServices

let pinkColor = UIColor(red: 204/255.0, green: 100/255.0, blue: 237/255.0, alpha: 1)

protocol SearchableListProtocol {
    var textToBeSearched: String { get }
}



extension BubblaNews: SearchableListProtocol {
    var textToBeSearched: String { return title }
}

class NewsTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var categoryTableViewController: CategoryTableViewController? = nil
    var newsItems = SearchableList<BubblaNews>(items: [])
    
    var category: String = CategoryTableViewController.recentString
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "refreshDummy:", name: UIApplicationWillEnterForegroundNotification, object: nil)
        showEmptyMessage(true, message: "")
        searchBar.hidden = true
        
        tableView.contentOffset = CGPoint(x: 0, y: searchBar.frame.height)
        NSOperationQueue().addOperationWithBlock {
            NSThread.sleepForTimeInterval(0.3)
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if !self.contentRecieved {
                    self.view.startActivityIndicator()
                }
            }
        }
        searchBar.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        registerForPreviewingWithDelegate(self, sourceView: view)
        title = category
        searchBar.placeholder = "Sök i \((category).lowercaseString)"
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedCell()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        title = category
        if !newsItems.isEmpty {
            refresh()
        }
    }
    
    var contentRecieved = false
    func refreshDummy(wtf: AnyObject) {
        refresh()
    }
    
    func refresh(refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.newsForCategory(category == "Senaste" ? nil : category) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.searchBar.hidden = false
                    self.showEmptyMessage(false, message: "")
                    let oldItems = self.newsItems
                    self.newsItems = SearchableList(items: Array(Set(newsItems)).sort { $1.publicationDate < $0.publicationDate })
                    self.newsItems.updateFilteredItemsToMatchSearchText(self.searchBar.text ?? "")
                    if oldItems.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        print("Updating table")
                        self.tableView.updateFromItems(self.newsItems.map { $0.id }, oldItems: oldItems.map({ $0.id }))
                        
                    }
                    if self.category == CategoryTableViewController.recentString {
                        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    }
                case .Error(let error):
                    if self.newsItems.isEmpty {
                        let errorMessage = (error as NSError).localizedDescription
                        self.showEmptyMessage(true, message: errorMessage)
                    } else {
                        print(error)
                    }
                    
                }
                self.contentRecieved = true
                self.refreshControl?.endRefreshing()
                self.view.stopActivityIndicator()
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsItems.count
    }
    
    var bubblaNewsWithFailedImages = Set<BubblaNews>()
    
    var imageForNewsItem = [BubblaNews: UIImage]()
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsItemTableViewCell", forIndexPath: indexPath) as! NewsItemTableViewCell
        let newsItem = newsItems[indexPath.row]
        cell.titleLabel.text = newsItem.title
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        cell.publicationDateLabel.text = dateFormatter.stringFromDate(newsItem.publicationDate).capitalizedString
        cell.publicationDateLabel.text = newsItem.publicationDate.readableString + (category == CategoryTableViewController.recentString ? " · \(newsItem.category)" : "")
        cell.urlLabel.text = newsItem.domain
        cell.unreadIndicator.hidden = newsItem.isRead
        cell.newsImageView.image = nil
        
        if let imageUrl = newsItem.ogImageUrl where !self.bubblaNewsWithFailedImages.contains(newsItem) {
            if let image = imageForNewsItem[newsItem] ?? UIImage(data: NSURLCache.sharedURLCache().cachedResponseForRequest(NSURLRequest(URL: imageUrl))?.data ?? NSData()) {
                //                    print("Used cached response \(newsItem.id)")
                cell.newsImageView.hidden = false
                cell.newsImageView.image = image
            } else {
                print("Retrieving image from server \(newsItem.title)")
                cell.newsImageView.startActivityIndicator()
                BubblaUrlService().imageFromUrl(imageUrl) { response in
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        switch response {
                        case .Success(let image):
                            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? NewsItemTableViewCell {
                                self.imageForNewsItem[newsItem] = image
                                cell.newsImageView.hidden = false
                                cell.newsImageView.image = image
                                tableView.reloadData()
                            }
                        case .Error:
                            self.bubblaNewsWithFailedImages.insert(newsItem)
                            if let cell = self.tableView.cellForRowAtIndexPath(indexPath) as? NewsItemTableViewCell {
                                cell.newsImageView.hidden = true
                                tableView.reloadData()
                            }
                        }
                        cell.newsImageView.stopActivityIndicator()
                    }
                }
            }
        } else {
            cell.newsImageView.hidden = true
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 200
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func newsForIndexPath(indexPath: NSIndexPath, isRead: Bool) {
        var newsItem = newsItems[indexPath.row]
        newsItem.isRead = isRead
        (tableView.cellForRowAtIndexPath(indexPath) as? NewsItemTableViewCell)?.unreadIndicator.hidden = newsItem.isRead
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        newsForIndexPath(indexPath, isRead: true)
        let safariViewController = safariViewControllerForIndexPath(indexPath)
        if splitViewController!.collapsed {
            presentViewController(safariViewController, animated: true, completion: nil)
        } else {
            splitViewController?.showDetailViewController(safariViewController, sender: self)
        }
    }
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var newsItem = newsItems[indexPath.row]
        return [UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: newsItem.isRead ? "Oläst" : "Läst") {
            (action, indexPath) in
            self.newsForIndexPath(indexPath, isRead: !newsItem.isRead)
            tableView.setEditing(false, animated: true)
            }]
    }
    
    func safariViewControllerForIndexPath(indexPath: NSIndexPath) -> UIViewController {
        let viewController = SFSafariViewController(URL: newsItems[indexPath.row].url, entersReaderIfAvailable: true)
        viewController.delegate = categoryTableViewController
        viewController.view.tintColor = pinkColor
        return viewController
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRowAtPoint(location),
                let cell = tableView.cellForRowAtIndexPath(highlightedIndexPath) else  { return nil }
            previewingContext.sourceRect = cell.frame
            self.newsForIndexPath(highlightedIndexPath, isRead: true)
            return safariViewControllerForIndexPath(highlightedIndexPath)
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        presentViewController(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension NewsTableViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        newsItems.updateFilteredItemsToMatchSearchText(searchText)
        tableView.reloadData()
    }
}
