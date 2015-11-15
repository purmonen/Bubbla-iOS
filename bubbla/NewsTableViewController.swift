import UIKit
import SafariServices

class NewsTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var allNewsItems: [BubblaNews] = []
    var newsItems: [BubblaNews] {
        return allNewsItems.filter {
            newsItem in
            if let searchText = searchBar.text where !searchText.isEmpty {
                let words = newsItem.title.lowercaseString.componentsSeparatedByString(" ")
                for searchWord in searchText.lowercaseString.componentsSeparatedByString(" ").filter({ !$0.isEmpty }) {
                    if words.filter({ $0.hasPrefix(searchWord) }).isEmpty {
                        return false
                    }
                }
            }
            return true
        }
    }
    
    var category: BubblaNewsCategory = .Recent
    
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
        title = category.rawValue
        searchBar.placeholder = "Sök i \(category.rawValue.lowercaseString)"
        refresh()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedCell()
        
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        title = category.rawValue
        if !allNewsItems.isEmpty {
            refresh()
        }
    }
    
    var contentRecieved = false
    func refreshDummy(wtf: AnyObject) {
        refresh()
    }
    
    func refresh(refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.newsForCategory(category) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.searchBar.hidden = false
                    self.showEmptyMessage(false, message: "")
                    let oldItems = self.allNewsItems
                    self.allNewsItems = Array(Set(newsItems)).sort { $1.publicationDate < $0.publicationDate }
                    if oldItems.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        print("Updating table")
                        self.tableView.updateFromItems(self.allNewsItems.map { $0.id }, oldItems: oldItems.map({ $0.id }))
   
                    }
                    if self.category == .Recent {
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
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        if let viewController = segue.sourceViewController as? CategoryTableViewController,
            let category = viewController.selectedCategory  {
                _BubblaApi.selectedCategory = category
                title = category.rawValue
                refresh()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsItems.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsItemTableViewCell", forIndexPath: indexPath) as! NewsItemTableViewCell
        let newsItem = newsItems[indexPath.row]
        cell.titleLabel.text = newsItem.title
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        cell.publicationDateLabel.text = dateFormatter.stringFromDate(newsItem.publicationDate).capitalizedString
        cell.publicationDateLabel.text = newsItem.publicationDate.readableString + (category == .Recent ? " - \(newsItem.category.rawValue)" : "")
        cell.urlLabel.text = newsItem.domain
        cell.unreadIndicator.hidden = newsItem.isRead
        return cell
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var newsItem = newsItems[indexPath.row]
        newsItem.isRead = true
        (tableView.cellForRowAtIndexPath(indexPath) as! NewsItemTableViewCell).unreadIndicator.hidden = newsItem.isRead
        let safariViewController = SFSafariViewController(URL: newsItems[indexPath.row].url)
        safariViewController.modalInPopover = true
        
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
            newsItem.isRead = !newsItem.isRead
            tableView.setEditing(false, animated: true)
            (tableView.cellForRowAtIndexPath(indexPath) as! NewsItemTableViewCell).unreadIndicator.hidden = newsItem.isRead
            }]
    }
    
    func safariViewControllerForIndexPath(indexPath: NSIndexPath) -> SFSafariViewController {
        return SFSafariViewController(URL: newsItems[indexPath.row].url)
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRowAtPoint(location),
                let cell = tableView.cellForRowAtIndexPath(highlightedIndexPath) else  { return nil }
            previewingContext.sourceRect = cell.frame
            return safariViewControllerForIndexPath(highlightedIndexPath)
    }

    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        presentViewController(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension NewsTableViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.reloadData()
    }
}
