import UIKit

public struct BubblaNews: Hashable {
    let title: String
    let url: URL
    let publicationDate: Date
    let category: String
    let categoryType: String
    let id: Int
    let imageUrl: URL?
    let facebookUrl: URL?
    let twitterUrl: URL?
    
    public var hashValue: Int { return id }
    
    
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
    
    public static func categoriesWithTypesFromNewsItems(_ newsItems: [BubblaNews]) -> [(categoryType: String, categories: [String])] {
        let categoryTypes = Array(Set(newsItems.map { $0.categoryType }))
        var categories = [(categoryType: String, categories: [String])]()
        for categoryType in categoryTypes {
            categories.append((categoryType: categoryType, categories: Array(Set(newsItems.filter({ $0.categoryType == categoryType }).map({ $0.category}))).sorted()))
        }
        return categories
    }
}

public func ==(x: BubblaNews, y: BubblaNews) -> Bool {
    return x.id == y.id
}

public protocol UrlService {
    func dataFromUrl(_ url: URL, callback: @escaping  (Response<Data>) -> Void)
    func dataFromUrl(_ url: URL, body: Data, callback: @escaping (Response<Data>) -> Void)
}

extension UrlService {
    
    func imageFromUrl(_ url: URL, callback: @escaping  (Response<UIImage>) -> Void) {
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
				if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                    return Response<Any>.success(json)
				} else {
                    return .error(NSError(domain: "jsonParsing", code: 1337, userInfo: nil))
                }
			})
		}
	}
	
}

class BubblaUrlService: UrlService {
    func dataFromUrl(_ url: URL, callback: @escaping (Response<Data>) -> Void) {
        let session = URLSession.shared
        let request = NSMutableURLRequest(url: url)
		
		
		
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: {
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
        let request = NSMutableURLRequest(url: url)
        request.httpBody = body
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: {
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

let BubblaApi = _BubblaApi(urlService: BubblaUrlService())

class _BubblaApi {
    
    let urlService: UrlService
    
    init(urlService: UrlService) {
        self.urlService = urlService
        let cacheSizeDisk = 500*1024*1024
        let cacheSizeMemory = 500*1024*1024
        let urlCache = URLCache(memoryCapacity: cacheSizeMemory, diskCapacity: cacheSizeDisk, diskPath: "bubblaUrlCache")
        URLCache.shared = urlCache
    }
    
    fileprivate class var readNewsItemIds: [Int] {
        get {
        return (UserDefaults.standard["readNewsItemsIds"] as? [Int] ?? [])
        }
        
        set {
            UserDefaults.standard["readNewsItemsIds"] = newValue
        }
    }
    
    class var selectedCategory: String? {
        get {
        return UserDefaults.standard["selectedCategory"] as? String
        }
        
        set {
            UserDefaults.standard["selectedCategory"] = newValue
        }
    }
    
    func registerDevice(_ deviceToken: String, excludeCategories categories: [String], callback: @escaping (Response<Void>) -> Void) {
        do {
            let json = ["token": deviceToken, "excludedCategories": categories] as [String : Any]
            let body = try JSONSerialization.data(withJSONObject: json, options: [])
            urlService.dataFromUrl(serverUrl.appendingPathComponent("registerDevice"), body: body) {
                print($0)
                callback($0.map( {_ in return }))
            }
        } catch {
            print(error)
        }
    }
    
    //    let serverUrl = NSURL(string: "http://192.168.1.84:8001")!
    
    let serverUrl = URL(string: "http://54.93.109.96:8001")!
    
    func newsForCategory(_ category: String?, callback: @escaping (Response<[BubblaNews]>) -> Void) {
        urlService.jsonFromUrl(serverUrl.appendingPathComponent("news")) {
            callback($0 >>= { json in
                var newsItems = [BubblaNews]()
                if let jsonArray = json as? [AnyObject] {
                    for item in jsonArray {
                        if let title = item["title"] as? String,
                            let urlString = item["url"] as? String,
                            let url = URL(string: urlString),
                            let category = item["category"] as? String,
                            let categoryType = item["categoryType"] as? String,
                            let publicationDateTimestamp = item["publicationDate"] as? TimeInterval,
                            let id = item["id"] as? Int {
                                let publicationDate = Date(timeIntervalSince1970: publicationDateTimestamp)
                                let imageUrlString = item["imageUrl"] as? String
                                let imageUrl: URL? = imageUrlString != nil ? URL(string: imageUrlString!) : nil
                                let facebookUrlString = item["facebookUrl"] as? String
                                let facebookUrl: URL? = facebookUrlString != nil ? URL(string: facebookUrlString!) : nil
                                let twitterUrlString = item["twitterUrl"] as? String
                                let twitterUrl: URL? = twitterUrlString != nil ? URL(string: twitterUrlString!) : nil
                                newsItems.append(BubblaNews(title: title, url: url, publicationDate: publicationDate, category: category, categoryType: categoryType, id: id, imageUrl: imageUrl, facebookUrl: facebookUrl, twitterUrl: twitterUrl))
                        }
                    }
                }
                return .success(newsItems.filter { $0.category == category || category == nil })
                })
        }
    }
}
