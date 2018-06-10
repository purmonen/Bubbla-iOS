import Foundation

public struct AwsConfig {
	let identityPoolId: String
	let platformApplicationArn: String
	let newsJsonUrl: String
}

#if DEBUG
let coraxPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS_SANDBOX/Corax"
let bubblaPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS_SANDBOX/BubblaNews"
#else
let coraxPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS/Corax"
let bubblaPlatformApplicationArn = "arn:aws:sns:eu-central-1:312328711982:app/APNS/BubblaNews"
#endif

let BubblaAwsConfig = AwsConfig(
	identityPoolId: "eu-central-1:2ff9fe6f-2889-47cf-a9b7-5b97ca80e79c",
	platformApplicationArn: bubblaPlatformApplicationArn,
	newsJsonUrl: "https://s3.eu-central-1.amazonaws.com/bubbla-news/Bubbla"
)

let CoraxAwsConfig = AwsConfig(
	identityPoolId: "eu-central-1:2ff9fe6f-2889-47cf-a9b7-5b97ca80e79c",
	platformApplicationArn: coraxPlatformApplicationArn,
	newsJsonUrl: "https://s3.eu-central-1.amazonaws.com/bubbla-news/Corax"
)
