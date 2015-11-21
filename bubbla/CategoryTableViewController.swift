import UIKit
import SafariServices

class CategoryTableViewController: UITableViewController, UISplitViewControllerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        performSegueWithIdentifier("NewsSegue", sender: self)
        splitViewController?.maximumPrimaryColumnWidth = 350
        splitViewController?.delegate = self
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        if secondaryViewController is SFSafariViewController {
            return false
        }
        return true
    }
    
    func noNewsChosenViewController() -> UIViewController {
        return storyboard!.instantiateViewControllerWithIdentifier("NoNewsChosenViewController")
    }
    
    func splitViewController(splitViewController: UISplitViewController, separateSecondaryViewControllerFromPrimaryViewController primaryViewController: UIViewController) -> UIViewController? {
        if !(primaryViewController.childViewControllers.last is SFSafariViewController) {
            return noNewsChosenViewController()
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
            viewController.categoryTableViewController = self
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


extension CategoryTableViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        let barButtonItem = splitViewController!.displayModeButtonItem()
        UIApplication.sharedApplication().sendAction(barButtonItem.action, to: barButtonItem.target, from: nil, forEvent: nil)
        
    }
}