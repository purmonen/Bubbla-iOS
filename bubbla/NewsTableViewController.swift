import UIKit
import SafariServices





extension BubblaNews: SearchableListProtocol {
    var textToBeSearched: String { return title }
}

class NewsTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var categoryTableViewController: CategoryTableViewController? = nil
    var newsItems = SearchableList<BubblaNews>(items: [])
    
    var category: String = CategoryTableViewController.recentString
    
    var newsSource: String? = nil
    
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
        title = newsSource ?? category
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedCell()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        title = newsSource ?? category
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
        BubblaApi.newsForCategory(category == CategoryTableViewController.recentString || category == CategoryTableViewController.topNewsString || newsSource != nil ? nil : category) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.searchBar.hidden = false
                    self.showEmptyMessage(false, message: "")
                    let oldItems = self.newsItems
                
                    
                    self.newsItems = SearchableList(items: Array(Set(newsItems)).sort { $1.publicationDate < $0.publicationDate }.filter { self.category !=
                        CategoryTableViewController.topNewsString || $0.facebookUrl != nil })
                    
                    if let newsSource = self.newsSource {
                        self.newsItems = SearchableList(items: newsItems.sort { $1.publicationDate < $0.publicationDate }.filter { $0.domain == newsSource })
                    }
                    
                    self.newsItems.updateFilteredItemsToMatchSearchText(self.searchBar.text ?? "")
                    if oldItems.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        print("Updating table")
                        self.tableView.updateFromItems(self.newsItems.map { $0.id }, oldItems: oldItems.map({ $0.id }))
                    }
                    UIApplication.sharedApplication().applicationIconBadgeNumber = 0
                    self.showEmptyMessageIfNeeded()
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
        cell.newsItem = newsItem
        cell.newsTableViewController = self
        return cell
 
    }
    
    func facebookButtonClicked(sender: AnyObject) {
        if let row = sender.tag,
            let facebookPostUrl = newsItems[row].facebookPostUrl {
                presentViewController(safariViewControllerForUrl(facebookPostUrl, entersReaderIfAvailable: false))
        }
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
        presentViewController(safariViewControllerForUrl(newsItems[indexPath.row].url, entersReaderIfAvailable: true))
    }
    
    func openUrl(url: NSURL, entersReaderIfAvailable: Bool) {
        presentViewController(safariViewControllerForUrl(url, entersReaderIfAvailable: entersReaderIfAvailable))
    }
    
    
    func presentViewController(viewController: UIViewController) {
        if splitViewController!.collapsed {
            presentViewController(viewController, animated: true, completion: nil)
        } else {
            splitViewController?.showDetailViewController(viewController, sender: self)
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var newsItem = newsItems[indexPath.row]
        return [UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: newsItem.isRead ? NSLocalizedString("Unread", comment: "") : NSLocalizedString("Read", comment: "")) {
            (action, indexPath) in
            self.newsForIndexPath(indexPath, isRead: !newsItem.isRead)
            tableView.setEditing(false, animated: true)
            }]
    }
    
    func safariViewControllerForUrl(url: NSURL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(URL: url, entersReaderIfAvailable: entersReaderIfAvailable)
        viewController.delegate = categoryTableViewController
        viewController.view.tintColor = UIApplication.sharedApplication().windows.first?.tintColor
        return viewController
    }
    
    func showEmptyMessageIfNeeded() {
        showEmptyMessage(newsItems.isEmpty, message: NSLocalizedString("No news", comment: ""))
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRowAtPoint(location),
                let cell = tableView.cellForRowAtIndexPath(highlightedIndexPath) else  { return nil }
            previewingContext.sourceRect = cell.frame
            self.newsForIndexPath(highlightedIndexPath, isRead: true)
            return safariViewControllerForUrl(newsItems[highlightedIndexPath.row].url, entersReaderIfAvailable: true)
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        presentViewController(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension NewsTableViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        newsItems.updateFilteredItemsToMatchSearchText(searchText)
        showEmptyMessageIfNeeded()
        tableView.reloadData()
    }
    
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        self.searchBar(searchBar, textDidChange: "")
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        searchBar.showsCancelButton = !(searchBar.text ?? "").isEmpty
    }
}
