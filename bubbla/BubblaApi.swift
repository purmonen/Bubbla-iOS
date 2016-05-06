import UIKit

public struct BubblaNews: Hashable {
    let title: String
    let url: NSURL
    let publicationDate: NSDate
    let category: String
    let categoryType: String
    let id: Int
    let imageUrl: NSURL?
    let facebookUrl: NSURL?
    let twitterUrl: NSURL?
    
    public var hashValue: Int { return id }
    
    
    var facebookPostUrl: NSURL? {
        if let facebookUrl = facebookUrl,
            let path = facebookUrl.absoluteString.componentsSeparatedByString("/").last {
                let pageIdAndPostIdSplit = path.componentsSeparatedByString("_")
                if  pageIdAndPostIdSplit.count == 2 {
                    let pageId = pageIdAndPostIdSplit[0]
                    let postId = pageIdAndPostIdSplit[1]
                    return NSURL(string: "https://www.facebook.com/\(pageId)/posts/\(postId)")
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
        let urlComponents = url.absoluteString.componentsSeparatedByString("/")
        var domain = ""
        if urlComponents.count > 2 {
            domain = urlComponents[2].stringByReplacingOccurrencesOfString("www.", withString: "")
        }
        return domain
    }
    
    public static func categoriesWithTypesFromNewsItems(newsItems: [BubblaNews]) -> [(categoryType: String, categories: [String])] {
        let categoryTypes = Array(Set(newsItems.map { $0.categoryType }))
        var categories = [(categoryType: String, categories: [String])]()
        for categoryType in categoryTypes {
            categories.append((categoryType: categoryType, categories: Array(Set(newsItems.filter({ $0.categoryType == categoryType }).map({ $0.category}))).sort()))
        }
        return categories
    }
}

public func ==(x: BubblaNews, y: BubblaNews) -> Bool {
    return x.id == y.id
}

public protocol UrlService {
    func dataFromUrl(url: NSURL, callback: Response<NSData> -> Void)
    func dataFromUrl(url: NSURL, body: NSData, callback: Response<NSData> -> Void)
}

extension UrlService {
    
    func imageFromUrl(url: NSURL, callback: Response<UIImage> -> Void) {
        dataFromUrl(url) {
            callback($0 >>= { data in
                if let image = UIImage(data: data) {
                    return .Success(image)
                }
                return .Error(NSError(domain: "imageFromUrl", code: 1337, userInfo: nil))
                })
        }
    }
    
    func jsonFromUrl(url: NSURL, callback: Response<AnyObject> -> Void) {
        dataFromUrl(url) {
            callback($0 >>= { data in
                do {
                    return .Success(try NSJSONSerialization.JSONObjectWithData(data, options: []))
                } catch {
                    return .Error(error)
                }
                })
        }
    }
    
}

class BubblaUrlService: UrlService {
    func dataFromUrl(url: NSURL, callback: Response<NSData> -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            if let data = data {
                callback(.Success(data))
            } else if let error = error {
                callback(.Error(error))
            } else {
                callback(.Error(NSError(domain: "dataFromUrl", code: 1337, userInfo: nil)))
            }
        }
        dataTask.resume()
    }
    
    func dataFromUrl(url: NSURL, body: NSData, callback: Response<NSData> -> Void) {
        let session = NSURLSession.sharedSession()
        let request = NSMutableURLRequest(URL: url)
        request.HTTPBody = body
        request.HTTPMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            if let data = data {
                callback(.Success(data))
            } else if let error = error {
                callback(.Error(error))
            } else {
                callback(.Error(NSError(domain: "dataFromUrl", code: 1337, userInfo: nil)))
            }
        }
        dataTask.resume()
    }
    
}

let BubblaApi = _BubblaApi(urlService: BubblaUrlService())

class _BubblaApi {
    
    let urlService: UrlService
    
    init(urlService: UrlService) {
        self.urlService = urlService
        let cacheSizeDisk = 500*1024*1024
        let cacheSizeMemory = 500*1024*1024
        let urlCache = NSURLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: "bubblaUrlCache")
        NSURLCache.setSharedURLCache(urlCache)
    }
    
    private class var readNewsItemIds: [Int] {
        get {
        return (NSUserDefaults.standardUserDefaults()["readNewsItemsIds"] as? [Int] ?? [])
        }
        
        set {
            NSUserDefaults.standardUserDefaults()["readNewsItemsIds"] = newValue
        }
    }
    
    class var selectedCategory: String? {
        get {
        return NSUserDefaults.standardUserDefaults()["selectedCategory"] as? String
        }
        
        set {
            NSUserDefaults.standardUserDefaults()["selectedCategory"] = newValue
        }
    }
    
    func registerDevice(deviceToken: String, excludeCategories categories: [String], callback: Response<Void> -> Void) {
        do {
            let json = ["token": deviceToken, "excludedCategories": categories]
            let body = try NSJSONSerialization.dataWithJSONObject(json, options: [])
            urlService.dataFromUrl(serverUrl.URLByAppendingPathComponent("registerDevice"), body: body) {
                print($0)
                callback($0.map( {_ in return }))
            }
        } catch {
            print(error)
        }
    }
    
        let serverUrl = NSURL(string: "http://192.168.1.84:8001")!
    
//    let serverUrl = NSURL(string: "http://54.93.109.96:8001")!
    
    
    enum NewsSource: String {
        case Bubbla = "bubbla", Corax = "corax"
    }
    
    
    var newsSource: NewsSource = .Corax
    
    func newsForCategory(category: String?, callback: Response<[BubblaNews]> -> Void) {
        
        
        urlService.jsonFromUrl(NSURL(string: "news?source=\(newsSource.rawValue)", relativeToURL: serverUrl)!) {
            callback($0 >>= { json in
                var newsItems = [BubblaNews]()
                if let jsonArray = json as? [AnyObject] {
                    for item in jsonArray {
                        if let title = item["title"] as? String,
                            let urlString = item["url"] as? String,
                            let url = NSURL(string: urlString),
                            let category = item["category"] as? String,
                            let categoryType = item["categoryType"] as? String,
                            let publicationDateTimestamp = item["publicationDate"] as? NSTimeInterval,
                            let id = item["id"] as? Int {
                                let publicationDate = NSDate(timeIntervalSince1970: publicationDateTimestamp)
                                let imageUrlString = item["imageUrl"] as? String
                                let imageUrl: NSURL? = imageUrlString != nil ? NSURL(string: imageUrlString!) : nil
                                let facebookUrlString = item["facebookUrl"] as? String
                                let facebookUrl: NSURL? = facebookUrlString != nil ? NSURL(string: facebookUrlString!) : nil
                                let twitterUrlString = item["twitterUrl"] as? String
                                let twitterUrl: NSURL? = twitterUrlString != nil ? NSURL(string: twitterUrlString!) : nil
                                newsItems.append(BubblaNews(title: title, url: url, publicationDate: publicationDate, category: category, categoryType: categoryType, id: id, imageUrl: imageUrl, facebookUrl: facebookUrl, twitterUrl: twitterUrl))
                        }
                    }
                }
                return .Success(newsItems.filter { $0.category == category || category == nil })
                })
        }
    }
}