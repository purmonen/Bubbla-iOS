import UIKit

class NewsTableViewController: UITableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!

    var allNewsItems: [BubblaNews] = []
    var newsItems: [BubblaNews] {
        return allNewsItems.filter {
            newsItem in
            if let searchText = searchBar.text where !searchText.isEmpty {
                let words = newsItem.title.lowercaseString.componentsSeparatedByString(" ")
                for searchWord in searchText.lowercaseString.componentsSeparatedByString(" ") {
                    if words.filter({ $0.hasPrefix(searchWord) }).isEmpty {
                        return false
                    }
                }
            }
            return true
        }
    }
    
    
    var category: BubblaNewsCategory!
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        refresh()
        searchBar.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        registerForPreviewingWithDelegate(self, sourceView: view)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = category.rawValue
        searchBar.placeholder = "Sök \(category.rawValue.lowercaseString)"
        tableView.reloadData()
    }
    
    var contentRecieved = false
    
    func refresh(refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.newsForCategory(category) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.allNewsItems = newsItems.sort { $1.publicationDate < $0.publicationDate }
                    self.searchBar.hidden = false
                    self.showEmptyMessage(false, message: "")
                    self.tableView.reloadData()
                case .Error(let error):
                    print(error)
                    
                    let errorMessage = (error as NSError).localizedDescription
                    if self.newsItems.isEmpty {
                        self.showEmptyMessage(true, message: errorMessage)
                    } else {
                        
                    let alertController = UIAlertController(title: nil, message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    alertController.addAction(UIAlertAction(title: "Ok", style: .Default) {
                        action in
                        alertController.dismissViewControllerAnimated(true, completion: nil)
                        })
                    self.presentViewController(alertController, animated: true, completion: nil)
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
    
    var highlightedIndexPath: NSIndexPath?
    
    
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
        
        
        let urlComponents = newsItem.url.absoluteString.componentsSeparatedByString("/")
        var domain = ""
        if urlComponents.count > 2 {
            domain = urlComponents[2].stringByReplacingOccurrencesOfString("www.", withString: "")
        }
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        cell.publicationDateLabel.text = dateFormatter.stringFromDate(newsItem.publicationDate).capitalizedString
        cell.publicationDateLabel.text = newsItem.publicationDate.readableString
        cell.urlLabel.text = domain
        cell.categoryLabel.text = newsItem.category.rawValue
        cell.unreadIndicator.hidden = newsItem.isRead
        
        return cell
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? NewsViewController,
            let indexPath = tableView.indexPathForSelectedRow ?? highlightedIndexPath {
                let newsItem = newsItems[indexPath.row]
                viewController.newsItem = newsItem
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
                newsItem.read()
        }
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let newsItem = newsItems[indexPath.row]
        return [UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: newsItem.isRead ? "Oläst" : "Läst") {
            (action, indexPath) in
            if newsItem.isRead {
                newsItem.unread()
            } else {
                newsItem.read()
            }
            tableView.setEditing(false, animated: true)
            (tableView.cellForRowAtIndexPath(indexPath) as! NewsItemTableViewCell).unreadIndicator.hidden = newsItem.isRead
//            tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }]
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRowAtPoint(location),
                let cell = tableView.cellForRowAtIndexPath(highlightedIndexPath) else  { return nil }
            self.highlightedIndexPath = highlightedIndexPath
            
            let newsItem = newsItems[highlightedIndexPath.row]
            let viewController = storyboard!.instantiateViewControllerWithIdentifier("NewsViewController") as! NewsViewController
            viewController.newsItem = newsItem
            previewingContext.sourceRect = cell.frame
            return viewController
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        self.performSegueWithIdentifier("NewsViewController", sender: self)
    }
}

extension NewsTableViewController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.reloadData()
    }
}
