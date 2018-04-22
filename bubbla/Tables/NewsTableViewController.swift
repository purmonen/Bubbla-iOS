import UIKit
import SafariServices


class NewsTableViewController: RefreshableTableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var categoryTableViewController: CategoryTableViewController? = nil
    var category: String = CategoryTableViewController.recentString
    var newsSource: String? = nil
	
	func categorizedNewsItems(_ newsItems: [BubblaNews]) -> [BubblaNews] {
		let filteredNewsItems: [BubblaNews]
		if let newsSource = self.newsSource {
			filteredNewsItems = newsItems
				.sorted { $1.publicationDate < $0.publicationDate }
				.filter { $0.domain == newsSource }
		} else {
			switch self.category {
			case CategoryTableViewController.topNewsString:
				filteredNewsItems = newsItems.filter { $0.facebookUrl != nil }
			case CategoryTableViewController.radioNewsString:
				filteredNewsItems = newsItems.filter { $0.radioUrl != nil }
			case CategoryTableViewController.recentString:
				filteredNewsItems = newsItems
			default:
				filteredNewsItems = newsItems.filter { $0.category == self.category }
			}
		}
		return filteredNewsItems
	}
	
	var newsItems = [BubblaNews]() {
		didSet {
			data = SearchableList(items: categorizedNewsItems(newsItems))
		}
	}

	var data = SearchableList<BubblaNews>(items: []) {
		didSet {
			tableView.reloadData()
		}
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        registerForPreviewing(with: self, sourceView: view)
        title = newsSource ?? category
        searchBar.placeholder = NSLocalizedString("Search", comment: "")
		NotificationCenter.default.addObserver(self, selector: #selector(NewsTableViewController.refreshDummy(_:)), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }
	
	@objc func refreshDummy(_ wtf: AnyObject) {
		load()
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = newsSource ?? category
    }
	
	override func load() {
		BubblaApi.news { response in
			OperationQueue.main.addOperation {
				switch response {
				case .success(let newsItems):
					self.newsItems = newsItems
					self.successfulRefresh()
				case .error(let error):
					self.errorRefresh(error: error)
				}
			}
		}
	}
    
    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    var bubblaNewsWithFailedImages = Set<BubblaNews>()
    var imageForNewsItem = [BubblaNews: UIImage]()
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsItemTableViewCell", for: indexPath) as! NewsItemTableViewCell
        let newsItem = data[indexPath.row]
        cell.newsItem = newsItem
        cell.newsTableViewController = self
        return cell
 
    }
    
    func facebookButtonClicked(_ sender: AnyObject) {
        if let row = sender.tag,
            let facebookPostUrl = data[row].facebookPostUrl {
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
        var newsItem = data[indexPath.row]
        newsItem.isRead = isRead
        (tableView.cellForRow(at: indexPath) as? NewsItemTableViewCell)?.unreadIndicator.isHidden = newsItem.isRead
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        newsForIndexPath(indexPath, isRead: true)
        presentViewController(safariViewControllerForUrl(data[indexPath.row].url as URL, entersReaderIfAvailable: true))
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
        var newsItem = data[indexPath.row]
        return [UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: newsItem.isRead ? NSLocalizedString("Unread", comment: "") : NSLocalizedString("Read", comment: "")) {
            (action, indexPath) in
            self.newsForIndexPath(indexPath, isRead: !newsItem.isRead)
            tableView.setEditing(false, animated: true)
            }]
    }
    
    func safariViewControllerForUrl(_ url: URL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(url: url, entersReaderIfAvailable: entersReaderIfAvailable)
        viewController.delegate = categoryTableViewController
		if #available(iOS 10.0, *) {
			viewController.preferredControlTintColor = UIApplication.shared.windows.first?.tintColor
		}
        return viewController
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
        data.updateFilteredItemsToMatchSearchText(searchText)
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


