//
//  ServerTableViewController.swift
//  Bubbla
//
//  Created by Sami Purmonen on 2018-04-15.
//  Copyright © 2018 Sami Purmonen. All rights reserved.
//

import UIKit


class RefreshableTableViewController: UITableViewController {
	var contentRecieved = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
		tableView.showEmptyMessage(message: "")
		OperationQueue().addOperation {
			Thread.sleep(forTimeInterval: 0.3)
			OperationQueue.main.addOperation {
				if !self.contentRecieved {
					self.view.startActivityIndicator()
				}
			}
		}
		load()
	}
	
	@objc func refresh(_ refreshControl: UIRefreshControl? = nil) {
		refreshControl?.beginRefreshing()
		load()
	}
	
	func endRefreshing() {
		view.stopActivityIndicator()
		tableView.showContent()
		tableView.reloadData()
		refreshControl?.endRefreshing()
	}
	
	func load() {}
	
	
	func successfulRefresh() {
		tableView.showContent()
		finishedRefresh()
	}
	
	func errorRefresh(error: Error) {
		finishedRefresh()
		let numberOfRowsInTableView = (0..<tableView.numberOfSections)
			.map({section in tableView.numberOfRows(inSection: section)})
			.reduce(0, +)
		if numberOfRowsInTableView > 0 {
			showErrorAlert(error)
		} else {
			tableView.showEmptyMessage(message: error.localizedDescription)
		}
	}
	
	func finishedRefresh() {
		self.view.stopActivityIndicator()
		refreshControl?.endRefreshing()
		contentRecieved = true
	}
	
	deinit {
		print("Deinit RefreshableTableViewController")
	}
	
}
