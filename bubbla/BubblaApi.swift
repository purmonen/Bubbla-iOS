import UIKit
import AWSSNS

public struct AwsConfig {
	let identityPoolId: String
	let platformApplicationArn: String
	let newsJsonUrl: String
}


#if DEBUG
let coraxPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS_SANDBOX/BubblaNews"
let bubblaPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS_SANDBOX/BubblaNews"
#else
let coraxPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS/BubblaNews"
let bubblaPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS/BubblaNews"
#endif

let BubblaAwsConfig = AwsConfig(
	identityPoolId: "eu-central-1:2ff9fe6f-2889-47cf-a9b7-5b97ca80e79c",
	platformApplicationArn: bubblaPlatformApplicationArn,
	newsJsonUrl: "https://s3.eu-central-1.amazonaws.com/bubbla-news/bubbla.json"
)

let CoraxAwsConfig = AwsConfig(
	identityPoolId: "eu-central-1:2ff9fe6f-2889-47cf-a9b7-5b97ca80e79c",
	platformApplicationArn: coraxPlatformApplicationArn,
	newsJsonUrl: "https://s3.eu-central-1.amazonaws.com/bubbla-news/CoraxNews"
)

public struct BubblaNews {
	let title: String
	let url: URL
	let publicationDate: Date
	let category: String
	let id: String
	let imageUrl: URL?
	let facebookUrl: URL?
	let twitterUrl: URL?
	let radioUrl: URL?
	
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

var BubblaApi = _BubblaApi(newsSource: .Bubbla)

class _BubblaApi {
	
	let urlService: UrlService
	let awsConfig: AwsConfig
	let sns: AWSSNS
	
	init(newsSource: NewsSource, urlService: UrlService = BubblaUrlService()) {
		self.newsSource = newsSource
		self.urlService = urlService
		let cacheSizeDisk = 500*1024*1024
		let cacheSizeMemory = 500*1024*1024
		let urlCache = URLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: "bubblaUrlCache")
		URLCache.shared = urlCache
		self.awsConfig = newsSource == .Bubbla ? BubblaAwsConfig : CoraxAwsConfig
		let credentialsProvider = AWSCognitoCredentialsProvider(
			regionType: AWSRegionType.EUCentral1, identityPoolId: awsConfig.identityPoolId)
		let defaultServiceConfiguration = AWSServiceConfiguration(
			region: AWSRegionType.EUCentral1, credentialsProvider: credentialsProvider)
		AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
		let sns = AWSSNS.default()
		self.sns = sns
	}
	
	fileprivate class var readNewsItemIds: [String] {
		get {
			return (UserDefaults.standard["readNewsItemsIds"] as? [String] ?? [])
		}
		
		set {
			UserDefaults.standard["readNewsItemsIds"] = newValue as AnyObject?
		}
	}
	
	struct Topic {
		let topicArn: String
		let name: String
	}
	
	func listTopics(callback: @escaping (Response<[Topic]>) -> Void) {
		if let listTopicsRequest = AWSSNSListTopicsInput() {
			sns.listTopics(listTopicsRequest).continueWith(block: { (task: AWSTask<AWSSNSListTopicsResponse>) -> AnyObject? in
				print("Topics!")
				if let resultTopics = task.result?.topics {
					var topics = [Topic]()
					for topic in resultTopics {
						if let topicArn = topic.topicArn {
							if let topicName = topicArn.split(separator: ":").last {
								let topicNameSplit = topicName.split(separator: "_")
								if topicNameSplit.count == 2 {
									let newsSourceName = topicNameSplit[0]
									let category = String(topicNameSplit[1]).replacingOccurrences(of: "-", with: " ")
									if newsSourceName == self.newsSource.rawValue {
										topics.append(Topic(topicArn: topicArn, name: category))
									}
								}
								
							}
						}
					}
					callback(.success(topics))
				}
				if let error = task.error {
					callback(.error(error))
				}
				return nil
			})
		}
	}
	
	func registerDevice(_ deviceToken: String, excludeCategories: [String], callback: @escaping (Response<Void>) -> Void) {
		print("Registering device \(deviceToken)")
		let request = AWSSNSCreatePlatformEndpointInput()!
		request.token = deviceToken
		request.platformApplicationArn = awsConfig.platformApplicationArn
		sns.createPlatformEndpoint(request).continueWith(executor: AWSExecutor.default(), block: { (task: AWSTask<AWSSNSCreateEndpointResponse>) -> AnyObject? in
			if task.error != nil {
				print("Error: \(String(describing: task.error))")
			} else {
				let createEndpointResponse = task.result! as AWSSNSCreateEndpointResponse
				if let endpointArnForSNS = createEndpointResponse.endpointArn {
					UserDefaults.standard.set(endpointArnForSNS, forKey: "endpointArnForSNS")
					self.listTopics() {
						switch $0 {
						case .success(let topics):
							for topic in topics {
								if let subscriptionArn = UserDefaults.standard.string(forKey: topic.topicArn) {
									if excludeCategories.contains(topic.topicArn) {
										let unsubscribeRequest = AWSSNSUnsubscribeInput()!
										unsubscribeRequest.subscriptionArn = subscriptionArn
										print("Unsubscribing to \(topic.name)")
										self.sns.unsubscribe(unsubscribeRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) -> AnyObject? in
											if let error = task.error {
												print("Error in subscribe: \(String(describing: error))")
											} else {
												UserDefaults.standard.set(nil, forKey: topic.topicArn)
											}
											return nil
										})
									}
								} else {
									if !excludeCategories.contains(topic.topicArn) {
										let subscribeRequest = AWSSNSSubscribeInput()!
										subscribeRequest.topicArn = topic.topicArn
										subscribeRequest.endpoint = endpointArnForSNS
										subscribeRequest.protocols = "application"
										print("Subscribing to \(topic.name)")
										self.sns.subscribe(subscribeRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask<AWSSNSSubscribeResponse>) -> AnyObject? in
											if let subscriptionArn = task.result?.subscriptionArn {
												UserDefaults.standard.set(subscriptionArn, forKey: topic.topicArn)
											}
											if let error = task.error {
												print("Error in subscribe: \(String(describing: error))")
											} else {
											}
											return nil
										})
									}
								}
								
							}
						case .error(let err):
							print(err)
						}
					}
				}
			}
			return nil
		})
	}
	
	enum NewsSource: String {
		case Bubbla = "bubbla", Corax = "corax"
	}
	
	let newsSource: NewsSource
	
	func news(callback: @escaping (Response<[BubblaNews]>) -> Void) {
		urlService.jsonFromUrl(URL(string: awsConfig.newsJsonUrl)!) {
			callback($0 >>= { json in
				var newsItems = [BubblaNews]()
				if let jsonArray = json as? [[String: AnyObject]] {
					for item in jsonArray {
						if let title = item["title"] as? String,
							let urlString = item["url"] as? String,
							let url = URL(string: urlString),
							let category = item["category"] as? String,
							let publicationDateTimestamp = item["publicationDate"] as? TimeInterval,
							let id = item["id"] as? String {

							let publicationDate = Date(timeIntervalSince1970: publicationDateTimestamp)
							let imageUrlString = item["imageUrl"] as? String
							let imageUrl: URL? = imageUrlString != nil ? URL(string: imageUrlString!) : nil
							let facebookUrlString = item["facebookUrl"] as? String
							let facebookUrl: URL? = facebookUrlString != nil ? URL(string: facebookUrlString!) : nil
							let twitterUrlString = item["twitterUrl"] as? String
							let twitterUrl: URL? = twitterUrlString != nil ? URL(string: twitterUrlString!) : nil
							
							let radioUrlString = item["soundcloudUrl"] as? String
							let radioUrl: URL? = radioUrlString != nil ? URL(string: radioUrlString!) : nil
							newsItems.append(BubblaNews(title: title, url: url, publicationDate: publicationDate, category: category,
														id: id, imageUrl: imageUrl, facebookUrl: facebookUrl, twitterUrl: twitterUrl, radioUrl: radioUrl))
						}
					}
				}
				return .success(newsItems)
				})
		}
	}
	
	struct NewsSourceDistribution {
		let name: String
		let count: Int
		let totalCount: Int
		
		var percentage: Double {
			get {
				return Double(count) / Double(totalCount)
			}
		}
	}

	
	func newsSourceDistributionFromNewsItems(_ newsItems: [BubblaNews]) -> [NewsSourceDistribution] {
		return newsItems
			.map({$0.domain})
			.valueCount
			.map { domain, count in NewsSourceDistribution(name: domain, count: count, totalCount: newsItems.count) }
			.sorted { $0.percentage > $1.percentage }
	}
}

extension BubblaNews: Hashable {
	public var hashValue: Int { return id.hashValue }
}

extension BubblaNews: SearchableListProtocol {
	var textToBeSearched: String { return title }
}
