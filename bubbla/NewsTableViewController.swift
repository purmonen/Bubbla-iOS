import UIKit
import SafariServices

let pinkColor = UIColor(red: 204/255.0, green: 100/255.0, blue: 237/255.0, alpha: 1)



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
        
        NotificationCenter.default.addObserver(self, selector: "refreshDummy:", name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
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
        refreshControl?.addTarget(self, action: "refresh:", for: .valueChanged)
        registerForPreviewing(with: self, sourceView: view)
        title = category
        searchBar.placeholder = "Sök i \((category).lowercased())"
        refresh()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectSelectedCell()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        title = category
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
        BubblaApi.newsForCategory(category == CategoryTableViewController.recentString || category == CategoryTableViewController.topNewsString  ? nil : category) {
            response in
            OperationQueue.main.addOperation {
                switch response {
                case .success(let newsItems):
                    self.searchBar.isHidden = false
                    self.showEmptyMessage(false, message: "")
                    let oldItems = self.newsItems
                    self.newsItems = SearchableList(items: Array(Set(newsItems)).sorted { $1.publicationDate < $0.publicationDate }.filter { self.category !=  CategoryTableViewController.topNewsString || $0.facebookUrl != nil })
                    self.newsItems.updateFilteredItemsToMatchSearchText(self.searchBar.text ?? "")
                    if oldItems.isEmpty {
                        self.tableView.reloadData()
                    } else {
                        print("Updating table")
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
        cell.facebookButton.isHidden = newsItem.facebookUrl == nil
        cell.titleLabel.text = newsItem.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMMM, HH:mm"
        cell.publicationDateLabel.text = dateFormatter.string(from: newsItem.publicationDate).capitalized
        
        
        let showCategory = category == CategoryTableViewController.recentString || category == CategoryTableViewController.topNewsString
        cell.publicationDateLabel.text = newsItem.publicationDate.readableString + (showCategory ? " · \(newsItem.category)" : "")
        cell.urlLabel.text = newsItem.domain
        cell.unreadIndicator.isHidden = newsItem.isRead
        cell.newsImageView.image = nil
        cell.newsImageView.isHidden = newsItem.imageUrl == nil
        cell.facebookButton.tag = indexPath.row
        cell.facebookButton.addTarget(self, action: "facebookButtonClicked:", for: .touchUpInside)
        if let imageUrl = newsItem.imageUrl, !self.bubblaNewsWithFailedImages.contains(newsItem) {
            if let image = self.imageForNewsItem[newsItem] {
                cell.newsImageView.image = image
            } else {
                OperationQueue().addOperation {
                    if let image = UIImage(data: URLCache.shared.cachedResponse(for: URLRequest(url: imageUrl))?.data ?? Data()) {
                        OperationQueue.main.addOperation {
                            cell.newsImageView.image = image

                        }
                    } else {
                        print("Retrieving image from server \(newsItem.title)")
                        OperationQueue.main.addOperation {
                            cell.newsImageView.startActivityIndicator()
                            cell.newsImageView.image = UIImage(named: "blank")
                        }
                        BubblaUrlService().imageFromUrl(imageUrl) { response in
                            OperationQueue.main.addOperation {
                                switch response {
                                case .success(let image):
                                    if let cell = self.tableView.cellForRow(at: indexPath) as? NewsItemTableViewCell {
                                        self.imageForNewsItem[newsItem] = image
                                        cell.newsImageView.image = image
                                    }
                                case .error:
                                    self.bubblaNewsWithFailedImages.insert(newsItem)
                                    if let cell = self.tableView.cellForRow(at: indexPath) as? NewsItemTableViewCell {
                                        cell.newsImageView.isHidden = true
                                    }
                                }
                                cell.newsImageView.stopActivityIndicator()
                            }
                        }
                    }
                }
            }
        } else {
            cell.newsImageView.isHidden = true
        }
        
        return cell
    }
    
    func facebookButtonClicked(_ sender: AnyObject) {
        if let row = sender.tag,
            let facebookPostUrl = newsItems[row].facebookPostUrl {
                presentViewController(safariViewControllerForUrl(facebookPostUrl, entersReaderIfAvailable: false))
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
        presentViewController(safariViewControllerForUrl(newsItems[indexPath.row].url, entersReaderIfAvailable: true))
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
        return [UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: newsItem.isRead ? "Oläst" : "Läst") {
            (action, indexPath) in
            self.newsForIndexPath(indexPath, isRead: !newsItem.isRead)
            tableView.setEditing(false, animated: true)
            }]
    }
    
    func safariViewControllerForUrl(_ url: URL, entersReaderIfAvailable: Bool) -> UIViewController {
        let viewController = SFSafariViewController(url: url, entersReaderIfAvailable: entersReaderIfAvailable)
        viewController.delegate = categoryTableViewController
        viewController.view.tintColor = pinkColor
        return viewController
    }
    
    func showEmptyMessageIfNeeded() {
        showEmptyMessage(newsItems.isEmpty, message: "Inga nyheter")
    }
}

extension NewsTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint) -> UIViewController? {
            guard let highlightedIndexPath = tableView.indexPathForRow(at: location),
                let cell = tableView.cellForRow(at: highlightedIndexPath) else  { return nil }
            previewingContext.sourceRect = cell.frame
            self.newsForIndexPath(highlightedIndexPath, isRead: true)
            return safariViewControllerForUrl(newsItems[highlightedIndexPath.row].url, entersReaderIfAvailable: true)
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
