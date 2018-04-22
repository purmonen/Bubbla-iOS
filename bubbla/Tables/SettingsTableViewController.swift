//
//  SettingsTableViewController.swift
//  Bubbla
//
//  Created by Sami Purmonen on 2018-04-22.
//  Copyright © 2018 Sami Purmonen. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
	
	var newsItem: BubblaNews? = nil

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let viewController = segue.destination as? NewsAppearenceTableViewController {
			viewController.newsItem = newsItem
		}
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
	}
}
