import UIKit

class SettingsTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [Browser.All.count][section]
    }

    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Webbläsare"][section]
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BrowserTableViewCell", forIndexPath: indexPath)
        let browser = Browser.All[indexPath.row]
        cell.accessoryType = browser == Settings.browser ? .Checkmark : .None
        cell.textLabel?.text = browser.rawValue
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        Settings.browser = Browser.All[indexPath.row]
        
        tableView.reloadData()
    }
}
