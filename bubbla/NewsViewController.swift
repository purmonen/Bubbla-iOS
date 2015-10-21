import UIKit

class NewsViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var newsItem: BubblaNews!
    
    func webViewDidFinishLoad(webView: UIWebView) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.view.stopActivityIndicator()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.startActivityIndicator()
        webView.delegate = self
        webView.loadRequest(NSURLRequest(URL: newsItem.url))
    }
}
