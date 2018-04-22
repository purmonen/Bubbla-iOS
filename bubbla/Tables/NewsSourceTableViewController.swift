//
//  NewsSourceTableViewController.swift
//  Bubbla
//
//  Created by Sami Purmonen on 17/02/16.
//  Copyright © 2016 Sami Purmonen. All rights reserved.
//

import UIKit
import SafariServices

class NewsSourceTableViewController: UITableViewController {
	
	var newsSourceDistributions = [_BubblaApi.NewsSourceDistribution]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if newsSourceDistributions.isEmpty {
			tableView.showEmptyMessage(message: "No data")
		} else {
			tableView.showContent()
		}
	}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let newsTableViewController = segue.destination as? NewsTableViewController,
				let indexPath = tableView.indexPathForSelectedRow {
            newsTableViewController.newsSource = newsSourceDistributions[indexPath.row].name
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsSourceTableViewCell", for: indexPath)
        let newsSource = newsSourceDistributions[indexPath.row]
        cell.textLabel?.text = newsSource.name
        cell.detailTextLabel?.text = String(format: "%.01f", newsSource.percentage * 100) + "%"
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if newsSourceDistributions.count > 0 {
			return String(format: NSLocalizedString("The %d latest posts came from %d different sources", comment: ""), newsSourceDistributions.first?.totalCount ?? 0, newsSourceDistributions.count)
		}
		return nil
    }
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return newsSourceDistributions.count
	}
	
	deinit {
		print("DEALLOCATING NewsSourceTableViewController")
	}

}

