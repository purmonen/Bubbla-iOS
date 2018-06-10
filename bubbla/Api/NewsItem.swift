//
//  NewsItem.swift
//  Bubbla
//
//  Created by Sami Purmonen on 2018-04-25.
//  Copyright © 2018 Sami Purmonen. All rights reserved.
//

import Foundation

public struct BubblaNews: Codable {
	let title: String
	let url: URL
	let publicationDate: Date
	let category: String
	let id: String
	let imageUrl: String?
	let facebookUrl: URL?
	let twitterUrl: URL?
	let soundcloudUrl: URL?
	
	var facebookPostUrl: URL? {
		if let facebookUrl = facebookUrl,
			let path = facebookUrl.absoluteString.components(separatedBy: "/").last {
			let pageIdAndPostIdSplit = path.components(separatedBy: "_")
			if  pageIdAndPostIdSplit.count == 2 {
				let pageId = pageIdAndPostIdSplit[0]
				let postId = pageIdAndPostIdSplit[1]
				return URL(string: "https://www.facebook.com/\(pageId)/posts/\(postId)")
			}
		}
		return nil
	}
	
	public var isRead: Bool {
		get {
			return _BubblaApi.readNewsItemIds.contains(id)
		}
		set {
			if newValue {
				_BubblaApi.readNewsItemIds = Array(Set(_BubblaApi.readNewsItemIds + [id]))
			} else {
				_BubblaApi.readNewsItemIds = Array(Set(_BubblaApi.readNewsItemIds.filter { $0 != id }))
			}
		}
	}
	
	public var domain: String {
		let urlComponents = url.absoluteString.components(separatedBy: "/")
		var domain = ""
		if urlComponents.count > 2 {
			domain = urlComponents[2].replacingOccurrences(of: "www.", with: "")
		}
		return domain
	}
	
	public static func categoriesFromNewsItems(_ newsItems: [BubblaNews]) -> [String] {
		return Array(Set(newsItems.map { $0.category })).sorted()
	}
}

public func ==(x: BubblaNews, y: BubblaNews) -> Bool {
	return x.id == y.id
}

extension BubblaNews: Hashable {
	public var hashValue: Int { return id.hashValue }
}

extension BubblaNews: SearchableListProtocol {
	var textToBeSearched: String { return title }
}
