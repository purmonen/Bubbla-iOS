import UIKit

class CategoryTableViewController: UITableViewController, UISplitViewControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        performSegueWithIdentifier("NewsSegue", sender: self)
        
//        if let viewController = storyboard?.instantiateViewControllerWithIdentifier("NewsTableViewController") {
////            navigationController?.pushViewController(viewController, animated: false)
//            showViewController(viewController, sender: self)
//            
//        }
        
//        showViewController(storyboard!.instantiateViewControllerWithIdentifier("NewsTableViewController"), sender: self)
        splitViewController?.maximumPrimaryColumnWidth = 350
        splitViewController?.delegate = self
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {

        if let newsViewController = (secondaryViewController as? NewsViewController) {
            return newsViewController.newsItem == nil
        }
        
        return true
    }
    
    func splitViewController(splitViewController: UISplitViewController, showDetailViewController vc: UIViewController, sender: AnyObject?) -> Bool {
//        print(splitViewController.collapsed)
//        if splitViewController.collapsed {
//            showViewController(vc, sender: self)
//            
//            return true
//        } else {
//            let navController = splitViewController.viewControllers[1] as! UINavigationController
//            
//            let topDetailViewController = navController.viewControllers.last!;
//            if topDetailViewController is NewsTableViewController || (vc.respondsToSelector("shouldReplaceDetailedView") && vc.performSelector("shouldReplaceDetailedView") != nil) {
//                navController.setViewControllers([vc], animated: false)
//            } else {
//                navController.pushViewController(vc, animated: true)
//            }
//
//        }
        return false
    }

    override func viewWillAppear(animated: Bool) {
        deselectSelectedCell()

    }

    var selectedCategory: BubblaNewsCategory?

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BubblaNewsCategory.All.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("CategoryCell", forIndexPath: indexPath)
        cell.textLabel?.text = BubblaNewsCategory.All[indexPath.row].rawValue
        return cell
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let viewController = segue.destinationViewController as? NewsTableViewController {
            let category: BubblaNewsCategory
            if let indexPath = tableView.indexPathForSelectedRow {
                category = BubblaNewsCategory.All[indexPath.row]
                tableView.deselectRowAtIndexPath(indexPath, animated: false)
            } else {
                category = _BubblaApi.selectedCategory
            }
            viewController.category = category
            _BubblaApi.selectedCategory = category

        }
    }
}
