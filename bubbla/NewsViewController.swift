import UIKit

class NewsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    var newsItem: BubblaNews!

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadRequest(NSURLRequest(URL: newsItem.url))
    }
}
