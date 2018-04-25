//
//  UrlService.swift
//  Bubbla
//
//  Created by Sami Purmonen on 2018-04-25.
//  Copyright © 2018 Sami Purmonen. All rights reserved.
//

import UIKit

public protocol UrlService {
	func dataFromUrl(_ url: URL, callback: @escaping (Response<Data>) -> Void)
	func dataFromUrl(_ url: URL, body: Data, callback: @escaping (Response<Data>) -> Void)
}

extension UrlService {
	
	func imageFromUrl(_ url: URL, callback: @escaping (Response<UIImage>) -> Void) {
		dataFromUrl(url) {
			callback($0 >>= { data in
				if let image = UIImage(data: data) {
					return .success(image)
				}
				return .error(NSError(domain: "imageFromUrl", code: 1337, userInfo: nil))
				})
		}
	}
	
	func jsonFromUrl(_ url: URL, callback: @escaping (Response<Any>) -> Void) {
		dataFromUrl(url) {
			callback($0 >>= { data in
				do {
					return .success(try JSONSerialization.jsonObject(with: data, options: []))
				} catch {
					return .error(error)
				}
				})
		}
	}
}

class BubblaUrlService: UrlService {
	func dataFromUrl(_ url: URL, callback: @escaping (Response<Data>) -> Void) {
		let session = URLSession.shared
		let request = URLRequest(url: url)
		let dataTask = session.dataTask(with: request, completionHandler: {
			(data, response, error) in
			if let data = data {
				callback(.success(data))
			} else if let error = error {
				callback(.error(error))
			} else {
				callback(.error(NSError(domain: "dataFromUrl", code: 1337, userInfo: nil)))
			}
		})
		dataTask.resume()
	}
	
	func dataFromUrl(_ url: URL, body: Data, callback: @escaping (Response<Data>) -> Void) {
		let session = URLSession.shared
		var request = URLRequest(url: url)
		request.httpBody = body
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		let dataTask = session.dataTask(with: request, completionHandler: {
			(data, response, error) in
			if let data = data {
				callback(.success(data))
			} else if let error = error {
				callback(.error(error))
			} else {
				callback(.error(NSError(domain: "dataFromUrl", code: 1337, userInfo: nil)))
			}
		})
		dataTask.resume()
	}
}
