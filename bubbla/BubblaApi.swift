import UIKit
import SWXMLHash

public struct BubblaNews: Hashable {
    let title: String
    let url: NSURL
    let publicationDate: NSDate
    let category: BubblaNewsCategory
    let id: Int
    
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
    func xmlFromUrl(url: NSURL, callback: Response<XMLIndexer> -> Void) {
        dataFromUrl(url) {
            callback($0.map { SWXMLHash.parse($0) } )
        }
    }
    
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
    
    
    var color: UIColor {
        let index = BubblaNewsCategory.All.indexOf(self)!
        
        
        let x = CGFloat(index) / CGFloat(BubblaNewsCategory.All.count)
        
        
        
        return UIColor(red: CGFloat(rand() % 255) / 255.0, green: CGFloat(rand() % 255) / 255.0, blue: CGFloat(rand() % 255) / 255.0, alpha: 1)
    }
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
    
    class var imageUrlForBubblaNewsId: [Int:NSURL] {
        get {
        let string = (NSUserDefaults.standardUserDefaults()["imageUrlForBubblaNewsId2"] as? [String] ?? [])
        let tuples = string.map({ $0.componentsSeparatedByString("!") }).map({ (Int($0[0])!, NSURL(string: $0[1])!) })
        var dictionary = [Int: NSURL]()
        for (key, value) in tuples {
        dictionary[key] = value
        }
        return dictionary
        }
        set {
            let strings = newValue.map { "\($0)!\($1.absoluteString)" }
            NSUserDefaults.standardUserDefaults()["imageUrlForBubblaNewsId2"] = strings
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
        NSURL(string: "http://54.93.109.96:8001/registerDevice?token=\(deviceToken)")!.data({
            print($0)
            callback($0.map( {_ in return }))
        })
    }
    
    private func dateFromString(dateString: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en")
        
        // For some reason the server uses two different date formats for different categories!
        for format in ["dd MMM yyyy HH:mm:ss Z", "MMMM dd, yyyy - HH:mm"] {
            dateFormatter.dateFormat = format
            let components = dateString.componentsSeparatedByString(", ")
            if components.count > 0 {
                let dateStringNoDay = components[1..<components.count].joinWithSeparator(", ")
                if let date = dateFormatter.dateFromString(dateStringNoDay) {
                    return date
                }
            }
        }
        return nil
    }
    
    func newsForCategory(category: BubblaNewsCategory, callback: Response<[BubblaNews]> -> Void) {
        urlService.xmlFromUrl(category.rssUrl) {
            callback($0 >>= {
                xml in
                var newsItems = [BubblaNews]()
                for item in xml["rss"]["channel"]["item"] {
                    if let title = item["title"].element?.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet()),
                        let urlString = item["link"].element?.text,
                        let url = NSURL(string: urlString),
                        let publicationDateString = item["pubDate"].element?.text,
                        let categoryString = item["category"].element?.text,
                        let category = BubblaNewsCategory(rawValue: categoryString),
                        let guid = item["guid"].element?.text,
                        let id = Int(guid) {
                            let publicationDate = self.dateFromString(publicationDateString) ?? NSDate()
                            newsItems.append(BubblaNews(title: title, url: url, publicationDate: publicationDate, category: category, id: id))
                    }
                }
                return .Success(newsItems)
                })
        }
    }
    
    func ogImageUrlFromUrl(url: NSURL, callback: Response<NSURL> -> Void) {
        urlService.dataFromUrl(url) {
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
}