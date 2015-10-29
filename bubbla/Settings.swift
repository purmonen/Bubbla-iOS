import UIKit


enum Browser: String {
    case Bubbla = "Bubbla", Safari = "Safari"
    
    static let All = [Browser.Bubbla, Browser.Safari]
}

let Settings = _Settings()
class _Settings {
    
    private init() {}
    
    let Ω = NSUserDefaults.standardUserDefaults()
    
    var browser: Browser {
        get { return Browser(rawValue: Ω["browser"] as? String ?? "") ?? .Bubbla }
        set { Ω["browser"] = newValue.rawValue }
    }
}
