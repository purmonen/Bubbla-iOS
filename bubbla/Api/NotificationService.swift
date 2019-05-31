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
			self.sns.listTopics(listTopicsRequest).continueWith() { (task: AWSTask<AWSSNSListTopicsResponse>) -> AnyObject? in
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
			}
		}
	}
	
	private func endpointArnKeyForToken(_ deviceToken: String) -> String {
		return "endpointArnKeyForToken_\(deviceToken)"
	}
	
	private func getEndpointArnForToken(_ deviceToken: String) -> String? {
		return UserDefaults.standard.string(forKey: endpointArnKeyForToken(deviceToken))
	}
	
	private func setEndpointArnForToken(_ deviceToken: String, endpointArn: String) {
		return UserDefaults.standard.set(endpointArn, forKey: endpointArnKeyForToken(deviceToken))
	}
	
	func createEndpointForDeviceToken(_ deviceToken: String, callback: @escaping (Response<String>) -> Void) {
		if let endpointArn = getEndpointArnForToken(deviceToken),
			let attributes = AWSSNSGetEndpointAttributesInput() {
			attributes.endpointArn = endpointArn
			sns.getEndpointAttributes(attributes).continueWith() { (task: AWSTask<AWSSNSGetEndpointAttributesResponse>) in
				if task.error != nil {
					self.createNewEndpointForDeviceToken(deviceToken, callback: callback)
				} else {
					if var endpointAttributes = task.result?.attributes {
						let tokenKey = "Token"
						let enabledKey = "Enabled"
						let trueString = "true"
						if (endpointAttributes[tokenKey] != deviceToken || endpointAttributes[enabledKey]?.lowercased() != trueString) {
							endpointAttributes[tokenKey] = deviceToken
							endpointAttributes[enabledKey] = trueString
							if let attributesInput = try? AWSSNSSetEndpointAttributesInput(dictionary: endpointAttributes, error: ()) {
								self.sns.setEndpointAttributes(attributesInput).continueWith() { (task: AWSTask<AnyObject>) in
									if task.error != nil {
										self.createNewEndpointForDeviceToken(deviceToken, callback: callback)
									} else {
										callback(.success(endpointArn))
									}
									return nil
								}
							} else {
								self.createNewEndpointForDeviceToken(deviceToken, callback: callback)
							}
						} else {
							callback(.success(endpointArn))
						}
					} else {
						self.createNewEndpointForDeviceToken(deviceToken, callback: callback)
					}
				}
				return nil
			}
		} else {
			createNewEndpointForDeviceToken(deviceToken, callback: callback)
		}
	}
	
	private func createNewEndpointForDeviceToken(_ deviceToken: String, callback: @escaping (Response<String>) -> Void) {
		let request = AWSSNSCreatePlatformEndpointInput()!
		request.token = deviceToken
		request.platformApplicationArn = awsConfig.platformApplicationArn
		sns.createPlatformEndpoint(request).continueWith() { (task: AWSTask<AWSSNSCreateEndpointResponse>) in
			if let error = task.error {
				callback(.error(error))
			} else {
				if let endpointArn = task.result?.endpointArn {
					self.setEndpointArnForToken(deviceToken, endpointArn: endpointArn)
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
		self.sns.unsubscribe(unsubscribeRequest).continueWith() { (task: AWSTask) in
			if let error = task.error {
				print("Error in subscribe: \(String(describing: error))")
				callback(.error(error))
			} else {
				callback(.success(true))
			}
			return nil
		}
	}
	
	func subscribeEndpointArn(_ endpointArn: String, toTopicArn topicArn: String, callback: @escaping (Response<String>) -> Void) {
		let subscribeRequest = AWSSNSSubscribeInput()!
		subscribeRequest.topicArn = topicArn
		subscribeRequest.endpoint = endpointArn
		subscribeRequest.protocols = "application"
		self.sns.subscribe(subscribeRequest).continueWith() { (task: AWSTask<AWSSNSSubscribeResponse>) in
			if let error = task.error {
				print("Error in subscribe: \(String(describing: error))")
				callback(.error(error))
			} else {
				if let subscriptionArn = task.result?.subscriptionArn {
					callback(.success(subscriptionArn))
				}
			}
			return nil
		}
	}
	
}

struct Subscription {
	let subscriptionArn: String
	let topicArn: String
}
