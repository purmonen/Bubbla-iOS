import UIKit

public struct BubblaNews: Hashable {
    let title: String
    let url: NSURL
    let publicationDate: NSDate
    let category: BubblaNewsCategory
    let id: Int
    
    let ogImageUrl: NSURL?
    
    public var hashValue: Int { return id }
    
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
}

public func ==(x: BubblaNews, y: BubblaNews) -> Bool {
    return x.id == y.id
}

public protocol UrlService {
    func dataFromUrl(url: NSURL, callback: Response<NSData> -> Void)
}

extension UrlService {
    
    func ogImageUrlFromUrl(url: NSURL, callback: Response<NSURL> -> Void) {
        dataFromUrl(url) {
            callback($0 >>= { data in
                if let string = String(data: data, encoding: NSUTF8StringEncoding) {
                    if let ogImageRange = string.rangeOfString("<meta property=\"og:image\"[^>]+>", options: .RegularExpressionSearch) {
                        let ogImageString = string.substringWithRange(ogImageRange)
                        if let ogImageContentRange = ogImageString.rangeOfString("[^\"]+\\.(jpg|png|jpeg|gif)", options: .RegularExpressionSearch) {
                            let imageUrlString = ogImageString.substringWithRange(ogImageContentRange)
                            if let imageUrl = NSURL(string: imageUrlString) {
                                return .Success(imageUrl)
                            }
                        }
                    }
                }
                return .Error(NSError(domain: "ogImageUrlFromUrl", code: 1337, userInfo: nil))
            })
        }
    }
    
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
        let request = NSURLRequest(URL: url)
        let dataTask = session.dataTaskWithRequest(request) {
            (data, response, error) in
            if let data = data {
                callback(.Success(data))
            } else if let error = error {
                callback(.Error(error))
            } else {
                callback(.Error(NSError(domain: "getData", code: 1337, userInfo: nil)))
            }
        }
        dataTask.resume()
    }
}

enum BubblaNewsCategory: String {
    case Recent = "Senaste", World = "Världen", Sweden = "Sverige", Mixed = "Blandat", Media = "Media", Politics = "Politik", Opinion = "Opinion", Europe = "Europa", NorthAmerica = "Nordamerika", LatinAmerica = "Latinamerika", Asia = "Asien", MiddleEast = "Mellanöstern", Africa = "Afrika", Economics = "Ekonomi", Tech = "Teknik", Science = "Vetenskap"
    
    var rssUrl: NSURL {
        if self == Recent {
            return NSURL(string: "https://bubb.la/rss/nyheter")!
        }
        let path = rawValue.lowercaseString.stringByReplacingOccurrencesOfString("ä", withString: "a").stringByReplacingOccurrencesOfString("ö", withString: "o")
        return NSURL(string: "https://bubb.la/rss/\(path)")!
    }
    
    
    static let All: [BubblaNewsCategory] = [.Recent, .World, .Sweden, .Mixed, .Media, .Politics, .Opinion, .Europe, .NorthAmerica, .LatinAmerica, .Asia, .MiddleEast, .Africa, .Economics, .Tech, .Science]
    
}

let BubblaApi = _BubblaApi(urlService: BubblaUrlService())

class _BubblaApi {
    
    let urlService: UrlService
    
    init(urlService: UrlService) {
        self.urlService = urlService

    }
    
    private class var readNewsItemIds: [Int] {
        get {
        return (NSUserDefaults.standardUserDefaults()["readNewsItemsIds"] as? [Int] ?? [])
        }
        
        set {
            NSUserDefaults.standardUserDefaults()["readNewsItemsIds"] = newValue
        }
    }
    
    class var selectedCategory: BubblaNewsCategory {
        get {
        return BubblaNewsCategory(rawValue: (NSUserDefaults.standardUserDefaults()["selectedCategory"] as? String ?? "")) ?? .Recent
        }
        
        set {
            NSUserDefaults.standardUserDefaults()["selectedCategory"] = newValue.rawValue
        }
    }
    
    func registerDevice(deviceToken: String, callback: Response<Void> -> Void) {
        urlService.dataFromUrl(NSURL(string: "http://54.93.109.96:8001/registerDevice?token=\(deviceToken)")!) {
            print($0)
            callback($0.map( {_ in return }))
        }
    }
    
    func newsForCategory(category: BubblaNewsCategory, callback: Response<[BubblaNews]> -> Void) {
        urlService.jsonFromUrl(NSURL(string: "http://192.168.1.84:8001/news")!) {
            callback($0 >>= { json in
                var newsItems = [BubblaNews]()
                if let jsonArray = json as? [AnyObject] {
                    for item in jsonArray {
                        if let title = item["title"] as? String,
                            let urlString = item["url"] as? String,
                            let url = NSURL(string: urlString),
                            let categoryString = item["category"] as? String,
                            let category = BubblaNewsCategory(rawValue: categoryString),
                            let publicationDateTimestamp = item["publicationDate"] as? NSTimeInterval,
                            let id = item["id"] as? Int {
                                let publicationDate = NSDate(timeIntervalSince1970: publicationDateTimestamp)
                                let ogImageUrlString = item["ogImageUrl"] as? String
                                let ogImageUrl: NSURL? = ogImageUrlString != nil ? NSURL(string: ogImageUrlString!)! : nil
                                newsItems.append(BubblaNews(title: title, url: url, publicationDate: publicationDate, category: category, id: id, ogImageUrl: ogImageUrl))
                        }
                    }
                }
                return .Success(newsItems.filter { $0.category == category || category == .Recent })
            })
        }
    }
}