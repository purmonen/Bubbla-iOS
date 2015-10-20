
import UIKit
import SWXMLHash

enum Response<T> {
    case Success(T)
    case Error(ErrorType)
    
    func map<G>(transform: T -> G) -> Response<G> {
        switch self {
        case .Success(let value):
            return .Success(transform(value))
        case .Error(let error):
            return .Error(error)
        }
        
    }
    
    static func flatten<T>(response: Response<Response<T>>) -> Response<T> {
        switch response {
        case .Success(let innerResponse):
            return innerResponse
        case .Error(let error):
            return .Error(error)
        }
    }
    
    func flatMap<G>(transform: T -> Response<G>) -> Response<G> {
        return Response.flatten(map(transform))
    }
}

infix operator >>= {}
func >>=<T, G>(response: Response<T>, transform: T -> Response<G>) -> Response<G> {
    return response.flatMap(transform)
}

let BubblaApi = _BubblaApi()


public func <(x: NSDate, y: NSDate) -> Bool {
    return x.timeIntervalSince1970 < y.timeIntervalSince1970
}

public func ==(x: NSDate, y: NSDate) -> Bool {
    return x.timeIntervalSince1970 == y.timeIntervalSince1970
}

class _BubblaApi {
    private init() {}
    
    struct NewsItem {
        let title: String
        let url: NSURL
        let publicationDateString: String
        let publicationDate: NSDate
        let category: String
        let id: Int
        
        var isRead: Bool {
            return readNewsItemIds.contains(id)
        }
        
        func read() {
            readNewsItemIds = readNewsItemIds + [id]
        }
    }
    
    enum NewsCategory: String {
        case Recent = "Senaste", World = "Världen", Sweden = "Sverige", Mixed = "Blandat", Media = "Media", Politics = "Politik", Opinion = "Opinion", Europe = "Europa", NorthAmerica = "Nordamerika", LatinAmerica = "Latinamerika", Asia = "Asien", MiddleEast = "Mellanöstern", Africa = "Afrika", Economics = "Ekonomi", Tech = "Teknik", Science = "Vetenskap"
        
        var rssUrl: NSURL {
            if self == Recent {
                return NSURL(string: "https://bubb.la/rss/nyheter")!
            }
            let path = rawValue.lowercaseString.stringByReplacingOccurrencesOfString("ä", withString: "a").stringByReplacingOccurrencesOfString("ö", withString: "o")
            return NSURL(string: "https://bubb.la/rss/\(path)")!
        }
        
        
        static let All: [NewsCategory] = [.Recent, .World, .Sweden, .Mixed, .Media, .Politics, .Opinion, .Europe, .NorthAmerica, .LatinAmerica, .Asia, .MiddleEast, .Africa, .Economics, .Tech, .Science]
    }
    
    class var readNewsItemIds: [Int] {
        get {
            return (NSUserDefaults.standardUserDefaults().valueForKey("readNewsItemsIds") as? [Int] ?? [])
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue, forKey: "readNewsItemsIds")
        }
    }
    
    class var selectedCategory: NewsCategory {
        get {
            return NewsCategory(rawValue: (NSUserDefaults.standardUserDefaults().valueForKey("selectedCategory") as? String ?? "")) ?? .Recent
        }
        
        set {
            NSUserDefaults.standardUserDefaults().setValue(newValue.rawValue, forKey: "selectedCategory")
        }
    }
    
    func getData(url: NSURL, callback: Response<NSData> -> Void) {
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
    
    func getXML(url: NSURL, callback: Response<XMLIndexer> -> Void) {
        getData(url) {
            callback($0.map { SWXMLHash.parse($0) } )
        }
    }
    
    func dateFromString(dateString: String) -> NSDate? {
//        let month = dateString.componentsSeparatedByString(", ")[1].componentsSeparatedByString(" ")[0]
//        let day = Int(dateString.componentsSeparatedByString(", ")[1].componentsSeparatedByString(" ")[1])
//        
//        let year = Int(dateString.componentsSeparatedByString(", ")[2].componentsSeparatedByString(" - ")[0])
//        let hours = Int(dateString.componentsSeparatedByString(", ")[0].componentsSeparatedByString(" - ")[1].componentsSeparatedByString(":")[0])
//        let seconds = Int(dateString.componentsSeparatedByString(", ")[0].componentsSeparatedByString(" - ")[1].componentsSeparatedByString(":")[1])
        
        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MMMM dd, yyyy - HH:mm"
        dateFormatter.locale = NSLocale(localeIdentifier: "en")
        
        
        let components = dateString.componentsSeparatedByString(", ")
        if components.count > 0 {
            let dateStringNoDay = components[1..<components.count].joinWithSeparator(", ")
            let date = dateFormatter.dateFromString(dateStringNoDay)
            return date
        }
        return nil
        
    }
    
    func getNewsForCategory(category: NewsCategory, callback: Response<[NewsItem]> -> Void) {
        getXML(category.rssUrl) {
            callback($0 >>= {
                xml in
                var newsItems = [NewsItem]()
                for item in xml["rss"]["channel"]["item"] {
                    if let title = item["title"].element?.text,
                        let urlString = item["link"].element?.text,
                        let url = NSURL(string: urlString),
                        let publicationDateString = item["pubDate"].element?.text,
                        let category = item["category"].element?.text,
                        let guid = item["guid"].element?.text,
                        let id = Int(guid) {
                            let publicationDate = self.dateFromString(publicationDateString) ?? NSDate()
                            newsItems.append(NewsItem(title: title, url: url, publicationDateString: publicationDateString, publicationDate: publicationDate, category: category, id: id))
                    }
                }
                return .Success(newsItems)
            })
            
        }
    }
    
}