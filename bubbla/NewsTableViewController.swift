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
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewsTableViewController.refreshDummy(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        showEmptyMessage(true, message: "")
        searchBar.isHidden = true
        
        tableView.contentOffset = CGPoint(x: 0, y: searchBar.frame.height)
        OperationQueue().addOperation {
            Thread.sleep(forTimeInterval: 0.3)
            OperationQueue.main.addOperation {
                if !self.contentRecieved {
                    self.view.startActivityIndicator()
                }
            }
        }
        searchBar.delegate = self
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 40, bottom: 0, right: 0)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(NewsTableViewController.refresh(_:)), for: .valueChanged)
        registerForPreviewing(with: self, sourceView: view)
        title = newsSource ?? category
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedCell()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = newsSource ?? category
        if !newsItems.isEmpty {
            refresh()
        }
    }
    
    var contentRecieved = false
    func refreshDummy(_ wtf: AnyObject) {
        refresh()
    }
    
    func refresh(_ refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.news() {
            response in
            OperationQueue.main.addOperation {
                switch response {
                case .success(let newsItems):
                    self.searchBar.isHidden = false
                    self.showEmptyMessage(false, message: "")
                    let oldItems = self.newsItems
					let filteredNewsItems: [BubblaNews]
					switch self.category {
					case CategoryTableViewController.topNewsString:
						filteredNewsItems = newsItems.filter { $0.facebookUrl != nil }
					case CategoryTableViewController.radioNewsString:
						filteredNewsItems = newsItems.filter { $0.radioUrl != nil }
					case CategoryTableViewController.recentString:
						filteredNewsItems = newsItems
					default:
						if self.newsSource != nil {
							filteredNewsItems = newsItems
						} else {
							filteredNewsItems = newsItems.filter { $0.category == self.category }
						}
					}
                    self.newsItems = SearchableList(items: Array(Set(filteredNewsItems)).sorted { $1.publicationDate < $0.publicationDate })
                    if let newsSource = self.newsSource {
                        self.newsItems = SearchableList(items: newsItems.sorted { $1.publicationDate < $0.publicationDate }.filter { $0.domain == newsSource })
                    }
                    self.newsItems.updateFilteredItemsToMatchSearchText(self.searchBar.text ?? "")
                    if oldItems.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        self.tableView.updateFromItems(self.newsItems.map { $0.id }, oldItems: oldItems.map({ $0.id }))
                    }
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    self.showEmptyMessageIfNeeded()
                case .error(let error):
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
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return newsItems.count
    }
    
    var bubblaNewsWithFailedImages = Set<BubblaNews>()
    
    var imageForNewsItem = [BubblaNews: UIImage]()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsItemTableViewCell", for: indexPath) as! NewsItemTableViewCell
        let newsItem = newsItems[indexPath.row]
        cell.newsItem = newsItem
        cell.newsTableViewController = self
        return cell
 
    }
    
    func facebookButtonClicked(_ sender: AnyObject) {
        if let row = sender.tag,
            let facebookPostUrl = newsItems[row].facebookPostUrl {
                presentViewController(safariViewControllerForUrl(facebookPostUrl as URL, entersReaderIfAvailable: false))
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func newsForIndexPath(_ indexPath: IndexPath, isRead: Bool) {
        var newsItem = newsItems[indexPath.row]
        newsItem.isRead = isRead
        (tableView.cellForRow(at: indexPath) as? NewsItemTableViewCell)?.unreadIndicator.isHidden = newsItem.isRead
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        newsForIndexPath(indexPath, isRead: true)
        presentViewController(safariViewControllerForUrl(newsItems[indexPath.row].url as URL, entersReaderIfAvailable: true))
    }
    
    func openUrl(_ url: URL, entersReaderIfAvailable: Bool) {
        presentViewController(safariViewControllerForUrl(url, entersReaderIfAvailable: entersReaderIfAvailable))
    }
    
    
    func presentViewController(_ viewController: UIViewController) {
        if splitViewController!.isCollapsed {
            present(viewController, animated: true, completion: nil)
        } else {
            splitViewController?.showDetailViewController(viewController, sender: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var newsItem = newsItems[indexPath.row]
        return [UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: newsItem.isRead ? NSLocalizedString("Unread", comment: "") : NSLocalizedString("Read", comment: "")) {
            (action, indexPath) in
            self.newsForIndexPath(indexPath, isRead: !newsItem.isRead)
            tableView.setEditing(false, animated: true)
            }]
    }
    
    func safariViewControllerForUrl(_ url: URL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(url: url, entersReaderIfAvailable: entersReaderIfAvailable)
        viewController.delegate = categoryTableViewController
        viewController.view.tintColor = UIApplication.shared.windows.first?.tintColor
        return viewController
    }
    
    func showEmptyMessageIfNeeded() {
        showEmptyMessage(newsItems.isEmpty, message: NSLocalizedString("No news", comment: ""))
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRow(at: location),
                let cell = tableView.cellForRow(at: highlightedIndexPath) else  { return nil }
            previewingContext.sourceRect = cell.frame
            self.newsForIndexPath(highlightedIndexPath, isRead: true)
            return safariViewControllerForUrl(newsItems[highlightedIndexPath.row].url as URL, entersReaderIfAvailable: true)
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        present(viewControllerToCommit, animated: true, completion: nil)
    }
}

extension NewsTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        newsItems.updateFilteredItemsToMatchSearchText(searchText)
        showEmptyMessageIfNeeded()
        tableView.reloadData()
    }
    
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        self.searchBar(searchBar, textDidChange: "")
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = !(searchBar.text ?? "").isEmpty
    }
}
