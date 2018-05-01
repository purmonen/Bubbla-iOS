
import Foundation


protocol TopicPreferences {
	func excludeTopic(_ topic: Topic) -> Bool
	func makeTopic(_ topic: Topic, excluded: Bool)
	
	func subscriptionArnForTopic(_ topic: Topic) -> String?
	func setSubscriptionArn(_ subscriptionArn: String?, forTopic topic: Topic)
}


struct _UserDefaultsTopicPreferences: TopicPreferences {
	private func excludeKeyForTopic(_ topic: Topic) -> String {
		return "excludeTopic_\(topic.topicArn)"
	}
	
	private func subscriptionArnKeyForTopic(_ topic: Topic) -> String {
		return "subscriptionArn_\(topic.topicArn)"
	}
	
	func makeTopic(_ topic: Topic, excluded: Bool) {
		return UserDefaults.standard.set(excluded, forKey: excludeKeyForTopic(topic))
	}
	
	func excludeTopic(_ topic: Topic) -> Bool {
		return UserDefaults.standard.bool(forKey: excludeKeyForTopic(topic))
	}
	
	func subscriptionArnForTopic(_ topic: Topic) -> String? {
		return UserDefaults.standard.string(forKey: subscriptionArnKeyForTopic(topic))
	}
	
	func setSubscriptionArn(_ subscriptionArn: String?, forTopic topic: Topic) {
		UserDefaults.standard.set(subscriptionArn, forKey: subscriptionArnKeyForTopic(topic))
	}
}
let UserDefaultsTopicPreferences = _UserDefaultsTopicPreferences()


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
