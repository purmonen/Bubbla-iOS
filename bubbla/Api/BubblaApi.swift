import Foundation


var BubblaApi = _BubblaApi(newsSource: .Bubbla, notificationService: AwsNotificationService(newsSource: .Bubbla))
class _BubblaApi {
	
	enum NewsSource: String {
		case Bubbla = "bubbla", Corax = "corax"
	}
	
	let newsSource: NewsSource
	let urlService: UrlService
	let awsConfig: AwsConfig
	let notificationService: NotificationService
	
	init(newsSource: NewsSource, urlService: UrlService = BubblaUrlService(), notificationService: NotificationService) {
		self.newsSource = newsSource
		self.urlService = urlService
		self.notificationService = notificationService
		awsConfig = newsSource == .Bubbla ? BubblaAwsConfig : CoraxAwsConfig
	}
	
	class var readNewsItemIds: [String] {
		get {
			return (UserDefaults.standard["readNewsItemsIds"] as? [String] ?? [])
		}
		
		set {
			UserDefaults.standard["readNewsItemsIds"] = newValue as AnyObject?
		}
	}
	

	// Too complicated, untested mess
	func registerDevice(_ deviceToken: String, topicPreferences: TopicPreferences, callback: @escaping (Response<Bool>) -> Void) {
		print("Registering device \(deviceToken)")
		notificationService.createEndpointForDeviceToken(deviceToken) { response in
			switch response {
			case .success(let endpointArn):
				self.notificationService.listTopics() { response in
					switch response {
					case .success(let topics):
						var unsubscribeSubscriptions = [String]()
						var subscribeToTopics = [Topic]()
						for topic in topics {
							let excludeTopic = topicPreferences.excludeTopic(topic)
							if let subscriptionArn = topicPreferences.subscriptionArnForTopic(topic) {
								if excludeTopic {
									unsubscribeSubscriptions.append(subscriptionArn)
								}
							} else {
								if !excludeTopic {
									subscribeToTopics.append(topic)
								}
							}
						}
						
						self.notificationService.subscribeEndpointArn(endpointArn, toTopicArns: subscribeToTopics.map { $0.topicArn }) {
							switch $0 {
							case .success(let subscriptions):
								for subscription in subscriptions {
									print("Subscribed to \(subscription.topicArn)")
									topicPreferences.setSubscriptionArn(subscription.subscriptionArn, forTopic: Topic(topicArn: subscription.topicArn))
								}
							case .error(let _):
								break
							}
							self.notificationService.unsubscribe(subscriptionArns: unsubscribeSubscriptions) {
								switch $0 {
								case .success(let unsubscriptions):
									for subscriptionArn in unsubscriptions {
										for topic in topics {
											if topicPreferences.subscriptionArnForTopic(topic) == subscriptionArn {
												print("Unsubscribed to \(topic.topicArn)")
												topicPreferences.setSubscriptionArn(nil, forTopic: topic)
											}
										}
									}
								case .error(let _):
									break
								}
								callback(.success(true))
							}
						}
					case .error(let error):
						callback(.error(error))
					}
				}
			case .error(let error):
				callback(.error(error))
			}
		}
	}
	
	
	func news(callback: @escaping (Response<[BubblaNews]>) -> Void) {
		urlService.dataFromUrl(URL(string: awsConfig.newsJsonUrl)!) {
			callback($0 >>= { json in
				do {
					let decoder = JSONDecoder()
					decoder.dateDecodingStrategy = .secondsSince1970
					let newsItems = try decoder.decode([BubblaNews].self, from: json)
					return .success(newsItems)
				} catch (let error) {
					print(error)
					return .error(error)
				}
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

