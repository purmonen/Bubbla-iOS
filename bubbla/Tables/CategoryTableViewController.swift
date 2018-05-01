import UIKit
import SafariServices


class CategoryTableViewController: RefreshableTableViewController {
    
    static let recentString = NSLocalizedString("Latest news", comment: "")
    static let topNewsString = NSLocalizedString("Top news", comment: "")
	static let radioNewsString = NSLocalizedString("Radio news", comment: "")
	
	var newsItems = [BubblaNews]() {
		didSet {
			let categories = Array(Set(newsItems.map { $0.category })).sorted()
			var fixedCategories = [CategoryTableViewController.recentString, CategoryTableViewController.topNewsString]
			if BubblaApi.newsSource == .Bubbla {
				fixedCategories += [CategoryTableViewController.radioNewsString]
			}
			data = [fixedCategories, categories]
		}
	}
	
	var data = [[String]]() {
		didSet {
			tableView.reloadData()
		}
	}
	
	override func load() {
		BubblaApi.news() { response in
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
	
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegue(withIdentifier: "NewsSegue", sender: self)
        splitViewController?.maximumPrimaryColumnWidth = 350
        splitViewController?.delegate = self
    }
	
    func noNewsChosenViewController() -> UIViewController {
        return storyboard!.instantiateViewController(withIdentifier: "NoNewsChosenViewController")
    }

    override func viewWillAppear(_ animated: Bool) {
        tableView.deselectSelectedRow()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryTableViewCell", for: indexPath) as! CategoryTableViewCell
        let category = data[indexPath.section][indexPath.row]
        cell.categoryLabel.text = category
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.destination {
		case let viewController as NewsTableViewController:
			viewController.categoryTableViewController = self
			if let indexPath = tableView.indexPathForSelectedRow {
				viewController.category = data[indexPath.section][indexPath.row]
				tableView.deselectRow(at: indexPath, animated: false)
			} else {
				viewController.category = CategoryTableViewController.recentString
			}
		case let viewController as NewsSourceTableViewController:
			viewController.newsSourceDistributions = BubblaApi.newsSourceDistributionFromNewsItems(newsItems)
		case let viewController as SettingsTableViewController:
			let newsItemsWithImageAndFacebookLink = newsItems.filter { $0.imageUrl != nil && $0.facebookUrl != nil }
			viewController.newsItem = newsItemsWithImageAndFacebookLink.first
		default:
			break
		}
    }
}


extension CategoryTableViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        let barButtonItem = splitViewController!.displayModeButtonItem
        UIApplication.shared.sendAction(barButtonItem.action!, to: barButtonItem.target, from: nil, for: nil)
        
    }
}


extension CategoryTableViewController: UISplitViewControllerDelegate {
	func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
		if secondaryViewController is SFSafariViewController {
			return false
		}
		return true
	}
	
	func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {
		if !(primaryViewController.childViewControllers.last is SFSafariViewController) {
			return noNewsChosenViewController()
		}
		return nil
	}
}
