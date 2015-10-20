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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refresh()
        searchBar.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        registerForPreviewingWithDelegate(self, sourceView: view)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = _BubblaApi.selectedCategory.rawValue
        searchBar.placeholder = "Sök \(_BubblaApi.selectedCategory.rawValue.lowercaseString)"
        tableView.reloadData()
    }
    
    func refresh(refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.newsForCategory(_BubblaApi.selectedCategory) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.allNewsItems = newsItems.sort { $1.publicationDate < $0.publicationDate }
                    self.tableView.reloadData()
                case .Error(let error):
                    print(error)
                }
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        if let viewController = segue.sourceViewController as? CategoryTableViewController,
            let category = viewController.selectedCategory  {
            _BubblaApi.selectedCategory = category
            title = _BubblaApi.selectedCategory.rawValue
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
        let domain = newsItem.url.absoluteString.componentsSeparatedByString("/")[2]
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
