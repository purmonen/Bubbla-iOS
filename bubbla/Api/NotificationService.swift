//
//  NotificationService.swift
//  Bubbla
//
//  Created by Sami Purmonen on 2018-04-30.
//  Copyright © 2018 Sami Purmonen. All rights reserved.
//

import Foundation
import AWSSNS

protocol NotificationService {
	func listTopics(callback: @escaping (Response<[Topic]>) -> Void)
	func createEndpointForDeviceToken(_ deviceToken: String, callback: @escaping (Response<String>) -> Void)
	func unsubscribe(subscriptionArn: String, callback: @escaping (Response<Bool>) -> Void)
	func subscribeEndpointArn(_ endpointArn: String, toTopicArn topicArn: String, callback: @escaping (Response<String>) -> Void)
}


extension NotificationService {
	func unsubscribe(subscriptionArns: [String], unsubscriptions: [String] = [], callback: @escaping (Response<[String]>) -> Void) {
		if let subscriptionArn = subscriptionArns.first {
			unsubscribe(subscriptionArn: subscriptionArn) {
				switch $0 {
				case .success:
					let newUnsubscriptions = unsubscriptions + [subscriptionArn]
					self.unsubscribe(subscriptionArns: Array(subscriptionArns.dropFirst()), unsubscriptions: newUnsubscriptions, callback: callback)
				case .error(let error):
					callback(.error(error))
				}
			}
		} else {
			callback(.success(unsubscriptions))
		}
	}
	
	
	func subscribeEndpointArn(_ endpointArn: String, toTopicArns topicArns: [String], subscriptions: [Subscription] = [], callback: @escaping (Response<[Subscription]>) -> Void) {
		if let topicArn = topicArns.first {
			subscribeEndpointArn(endpointArn, toTopicArn: topicArn) {
				switch $0 {
				case .success(let subscriptionArn):
					let newSubscriptions = subscriptions + [Subscription(subscriptionArn: subscriptionArn, topicArn: topicArn)]
					self.subscribeEndpointArn(endpointArn, toTopicArns: Array(topicArns.dropFirst()), subscriptions: newSubscriptions, callback: callback)
				case .error(let error):
					callback(.error(error))
				}
			}
		} else {
			callback(.success(subscriptions))
		}
	}
}

struct AwsNotificationService: NotificationService {
	let awsConfig: AwsConfig
	let sns: AWSSNS
	
	init(newsSource: _BubblaApi.NewsSource) {
		self.awsConfig = newsSource == .Bubbla ? BubblaAwsConfig : CoraxAwsConfig
		let credentialsProvider = AWSCognitoCredentialsProvider(
			regionType: AWSRegionType.EUCentral1, identityPoolId: awsConfig.identityPoolId)
		let defaultServiceConfiguration = AWSServiceConfiguration(
			region: AWSRegionType.EUCentral1, credentialsProvider: credentialsProvider)
		AWSServiceManager.default().defaultServiceConfiguration = defaultServiceConfiguration
		let sns = AWSSNS.default()
		self.sns = sns
	}
	
	func listTopics(callback: @escaping (Response<[Topic]>) -> Void) {
		if let listTopicsRequest = AWSSNSListTopicsInput() {
			self.sns.listTopics(listTopicsRequest).continueWith(block: { (task: AWSTask<AWSSNSListTopicsResponse>) -> AnyObject? in
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
	
	
	func createEndpointForDeviceToken(_ deviceToken: String, callback: @escaping (Response<String>) -> Void) {
		let request = AWSSNSCreatePlatformEndpointInput()!
		request.token = deviceToken
		request.platformApplicationArn = awsConfig.platformApplicationArn
		sns.createPlatformEndpoint(request).continueWith(executor: AWSExecutor.default()) { (task: AWSTask<AWSSNSCreateEndpointResponse>) in
			if let error = task.error {
				callback(.error(error))
			} else {
				if let endpointArn = task.result?.endpointArn {
					callback(.success(endpointArn))
				} else {
					callback(.error(NSError(domain: "aws", code: 0, userInfo: [NSLocalizedDescriptionKey: "This should never happen?"])))
				}
			}
			return nil
		}
	}
	
	func unsubscribe(subscriptionArn: String, callback: @escaping (Response<Bool>) -> Void) {
		let unsubscribeRequest = AWSSNSUnsubscribeInput()!
		unsubscribeRequest.subscriptionArn = subscriptionArn
		self.sns.unsubscribe(unsubscribeRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask) in
			if let error = task.error {
				print("Error in subscribe: \(String(describing: error))")
				callback(.error(error))
			} else {
				callback(.success(true))
			}
			return nil
		})
	}
	
	func subscribeEndpointArn(_ endpointArn: String, toTopicArn topicArn: String, callback: @escaping (Response<String>) -> Void) {
		let subscribeRequest = AWSSNSSubscribeInput()!
		subscribeRequest.topicArn = topicArn
		subscribeRequest.endpoint = endpointArn
		subscribeRequest.protocols = "application"
		self.sns.subscribe(subscribeRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task: AWSTask<AWSSNSSubscribeResponse>) in
			if let error = task.error {
				print("Error in subscribe: \(String(describing: error))")
				callback(.error(error))
			} else {
				if let subscriptionArn = task.result?.subscriptionArn {
					callback(.success(subscriptionArn))
				}
			}
			return nil
		})
	}
	
}

struct Subscription {
	let subscriptionArn: String
	let topicArn: String
}
