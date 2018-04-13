import UIKit
import SafariServices

class CategoryTableViewController: UITableViewController, UISplitViewControllerDelegate {
    
    var categories = [(categoryType: String, categories: [String])]()
    
    static let recentString = NSLocalizedString("Latest news", comment: "")
    
    static let topNewsString = NSLocalizedString("Top news", comment: "")
	
	static let radioNewsString = NSLocalizedString("Radio news", comment: "")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(CategoryTableViewController.refresh(_:)), for: .valueChanged)
        refresh()
        
        performSegue(withIdentifier: "NewsSegue", sender: self)
        splitViewController?.maximumPrimaryColumnWidth = 350
        splitViewController?.delegate = self
    }
    
    @objc func refresh(_ refreshControl: UIRefreshControl? = nil) {
        refreshControl?.beginRefreshing()
        BubblaApi.news() { response in
            OperationQueue.main.addOperation {
                switch response {
                case .success(let newsItems):
                    self.showEmptyMessage(false, message: "")
                    let categories = BubblaNews.categoriesWithTypesFromNewsItems(newsItems)
					var fixedCategories = [CategoryTableViewController.recentString, CategoryTableViewController.topNewsString]
					if BubblaApi.newsSource == .Bubbla {
						fixedCategories += [CategoryTableViewController.radioNewsString]
					}
					self.categories = [(categoryType: "", fixedCategories)] + categories
                    self.tableView.reloadData()                    
                case .error(let error):
                    if self.categories.isEmpty {
                        let errorMessage = (error as NSError).localizedDescription
                        self.showEmptyMessage(true, message: errorMessage)
                    } else {
                        print(error)
                    }
                }
                self.refreshControl?.endRefreshing()
            }
        }
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        if secondaryViewController is SFSafariViewController {
            return false
        }
        return true
    }
    
    @IBAction func unwind(_ segue: UIStoryboardSegue) {}
    
    func noNewsChosenViewController() -> UIViewController {
        return storyboard!.instantiateViewController(withIdentifier: "NoNewsChosenViewController")
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
        if !(primaryViewController.childViewControllers.last is SFSafariViewController) {
            return noNewsChosenViewController()
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        deselectSelectedCell()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories[section].categories.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return categories[section].categoryType
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryTableViewCell", for: indexPath) as! CategoryTableViewCell
        
        
        let category = categories[indexPath.section].categories[indexPath.row]
        cell.categoryLabel.text = category
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? NewsTableViewController {
            viewController.categoryTableViewController = self
            let category: String
            if let indexPath = tableView.indexPathForSelectedRow {
                category = categories[indexPath.section].categories[indexPath.row]
                tableView.deselectRow(at: indexPath, animated: false)
            } else {
                category = CategoryTableViewController.recentString
            }
            viewController.category = category
        }

        if let navigationController = segue.destination as? UINavigationController,
            let viewController = navigationController.childViewControllers.first as? PushNotificationsTableViewController {
//            viewController.categories = Array(Set(categories.dropFirst().flatMap { $0.categories })).sorted()
        }
    }
}

extension CategoryTableViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        let barButtonItem = splitViewController!.displayModeButtonItem
        UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
        
    }
}
