import UIKit

class CategoryTableViewController: UITableViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegueWithIdentifier("NewsSegue", sender: self)
        splitViewController?.maximumPrimaryColumnWidth = 350
        splitViewController?.delegate = self
        splitViewController?.preferredDisplayMode = .AllVisible
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        
        if let newsViewController = secondaryViewController.childViewControllers.first as? NewsViewController {
            return newsViewController.newsItem == nil
        }
        
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        
        if !(primaryViewController.childViewControllers.last is UINavigationController) {
            if let newsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("NewsViewController") as? NewsViewController {
                return UINavigationController(rootViewController: newsViewController)
            }
        }
        return nil
    }
    
    override func viewWillAppear(animated: Bool) {
        deselectSelectedCell()
    }
    
    var selectedCategory: BubblaNewsCategory?
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sections.count
    }
    
    let sections: [[BubblaNewsCategory]] = [
        [.Recent],
        [.Economics, .Politics, .Opinion, .Science, .Tech, .Mixed],
        [.Sweden, .World, .Europe, .NorthAmerica, .Africa, .Asia, .LatinAmerica, .MiddleEast]
    ]
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["", "Ämne", "Geografiskt område"][section]
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell", forIndexPath: indexPath)
        cell.textLabel?.text = sections[indexPath.section][indexPath.row].rawValue
        return cell
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? NewsTableViewController {
            let category: BubblaNewsCategory
            if let indexPath = tableView.indexPathForSelectedRow {
                category = sections[indexPath.section][indexPath.row]
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            } else {
                category = _BubblaApi.selectedCategory
            }
            viewController.category = category
            _BubblaApi.selectedCategory = category
            
        }
    }
}
