
import UIKit

class NewsTableViewController: UITableViewController, UIViewControllerPreviewingDelegate {
    
    var newsItems: [_BubblaApi.NewsItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh:", forControlEvents: .ValueChanged)
        registerForPreviewingWithDelegate(self, sourceView: view)

    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        title = _BubblaApi.selectedCategory.rawValue
        refresh()
    }
    
    func refresh(refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.getNewsForCategory(_BubblaApi.selectedCategory) {
            response in
            NSOperationQueue.mainQueue().addOperationWithBlock {
                switch response {
                case .Success(let newsItems):
                    self.newsItems = newsItems.sort { $1.publicationDate < $0.publicationDate }
                    self.tableView.reloadData()
                case .Error(let error):
                    print(error)
                }
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    @IBAction func unwind(segue: UIStoryboardSegue) {
        
    }
    
    var highlightedIndexPath: NSIndexPath?
    
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
        cell.urlLabel.text = domain
        cell.categoryLabel.text = newsItem.category
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
