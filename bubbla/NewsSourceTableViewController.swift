//
//  NewsSourceTableViewController.swift
//  Bubbla
//
//  Created by Sami Purmonen on 17/02/16.
//  Copyright © 2016 Sami Purmonen. All rights reserved.
//

import UIKit
import SafariServices


struct NewsSource {
    let name: String
    let percentage: Double
}

class NewsSourceTableViewController: UITableViewController {

    
    var newsSources = [NewsSource]()
    var newsItems = [BubblaNews]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        BubblaApi.newsForCategory(nil) {
            response in
            OperationQueue.main.addOperation {
                switch response {
                case .success(let newsItems):
                    self.newsItems = newsItems
                    var newsSourceCount = [String: Int]()
                    for newsItem in newsItems {
                        if newsSourceCount[newsItem.domain] == nil {
                           newsSourceCount[newsItem.domain] = 0
                        }
                        newsSourceCount[newsItem.domain]! += 1
                    }
                    var newsSources = [NewsSource]()
                    for (newsSource, count) in newsSourceCount {
                        newsSources += [NewsSource(name: newsSource, percentage: Double(count) / Double(newsItems.count))]
                    }
                    newsSources = newsSources.sorted { $0.percentage > $1.percentage }
                    self.newsSources = newsSources
                    self.tableView.reloadData()
                case .error:
                    break
                    
                }
            }
        }


        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    /*
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let newsSource = newsSources[indexPath.row]
        let url = NSURL(string: "http://\(newsSource.name)")!
        let viewController = SFSafariViewController(URL: url, entersReaderIfAvailable: false)
//        viewController.delegate = self
        viewController.view.tintColor = UIApplication.sharedApplication().windows.first?.tintColor
        presentViewController(viewController, animated: true, completion: nil)
    }
 */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newsTableViewController = segue.destination as? NewsTableViewController,
            let indexPath = tableView.indexPathForSelectedRow {
            newsTableViewController.newsSource = newsSources[indexPath.row].name
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return newsSources.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsSourceTableViewCell", for: indexPath)
        let newsSource = newsSources[indexPath.row]
        cell.textLabel?.text = newsSource.name
        cell.detailTextLabel?.text = String(format: "%.01f", newsSource.percentage * 100) + "%"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(format: NSLocalizedString("The %d latest posts came from %d different sources", comment: ""), newsItems.count, newsSources.count)
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
