import AWSSNS

var BubblaApi = _BubblaApi(newsSource: .Bubbla)

class _BubblaApi {
	
	enum NewsSource: String {
		case Bubbla = "bubbla", Corax = "corax"
	}
	
	let newsSource: NewsSource
	let urlService: UrlService
	let awsConfig: AwsConfig
	let sns: AWSSNS
	
	init(newsSource: NewsSource, urlService: UrlService = BubblaUrlService()) {
		self.newsSource = newsSource
		self.urlService = urlService
		
		// Why do cache stuff here?
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
	
	
	
	class var readNewsItemIds: [String] {
		get {
			return (UserDefaults.standard["readNewsItemsIds"] as? [String] ?? [])
		}
		
		set {
			UserDefaults.standard["readNewsItemsIds"] = newValue as AnyObject?
		}
	}
	
	struct Topic {
		let topicArn: String
		var name: String {
			get {
				if let topicName = topicArn.split(separator: ":").last {
					let topicNameSplit = topicName.split(separator: "_")
					if topicNameSplit.count == 2 {
						let topicName = String(topicNameSplit[1]).replacingOccurrences(of: "-", with: " ")
						return topicName
					}
				}
				return topicArn
			}
		}

		var newsSource: String {
			if let topicName = topicArn.split(separator: ":").last {
				let topicNameSplit = topicName.split(separator: "_")
				if topicNameSplit.count == 2 {
					let newsSourceName = topicNameSplit[0]
					return String(newsSourceName)
				}
			}
			return topicArn
		}
	}
	
	func listTopics(callback: @escaping (Response<[Topic]>) -> Void) {
		if let listTopicsRequest = AWSSNSListTopicsInput() {
			sns.listTopics(listTopicsRequest).continueWith(block: { (task: AWSTask<AWSSNSListTopicsResponse>) -> AnyObject? in
				print("Topics!")
				if let resultTopics = task.result?.topics {
					var topics = [Topic]()
					for topic in resultTopics {
						if let topicArn = topic.topicArn {
							let topic = Topic(topicArn: topicArn)
							if topic.newsSource == BubblaApi.newsSource.rawValue {
								topics.append(Topic(topicArn: topicArn))
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

