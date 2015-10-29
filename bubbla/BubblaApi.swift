import UIKit

public struct BubblaNews: Hashable {
    let title: String
    let url: NSURL
    let publicationDateString: String
    let publicationDate: NSDate
    let category: BubblaNewsCategory
    let id: Int
    
    public var hashValue: Int { return id }
    
    var isRead: Bool {
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
    
    var domain: String {
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

let BubblaApi = _BubblaApi()

class _BubblaApi {
    private init() {}
    
    
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
        NSURL(string: "http://54.93.109.96:8001/registerDevice?token=\(deviceToken)")!.data({
            print($0)
            callback($0.map( {_ in return }))
        })
    }
    
    private func dateFromString(dateString: String) -> NSDate? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en")
        
        // For some reason the server uses two different date formats for different categories!
        for format in ["dd MMM yyyy HH:mm:ss +02    00", "MMMM dd, yyyy - HH:mm"] {
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
        category.rssUrl.xml() {
            callback($0 >>= {
                xml in
                var newsItems = [BubblaNews]()
                for item in xml["rss"]["channel"]["item"] {
                    if let title = item["title"].element?.text,
                        let urlString = item["link"].element?.text,
                        let url = NSURL(string: urlString),
                        let publicationDateString = item["pubDate"].element?.text,
                        let categoryString = item["category"].element?.text,
                        let category = BubblaNewsCategory(rawValue: categoryString),
                        let guid = item["guid"].element?.text,
                        let id = Int(guid) {
                            let publicationDate = self.dateFromString(publicationDateString) ?? NSDate()
                            newsItems.append(BubblaNews(title: title, url: url, publicationDateString: publicationDateString, publicationDate: publicationDate, category: category, id: id))
                    }
                }
                return .Success(newsItems)
                })
        }
    }
}