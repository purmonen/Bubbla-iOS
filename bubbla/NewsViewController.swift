import UIKit
import WebKit

class NewsViewController: UIViewController, WKNavigationDelegate {

    var newsItem: BubblaNews!
    
    func webViewDidFinishLoad(webView: UIWebView) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.view.stopActivityIndicator()
        }
    }
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        view.stopActivityIndicator()
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        showErrorAlert(error)
        view.stopActivityIndicator()
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        if newsItem == nil {
//            dismissViewControllerAnimated(false, completion: nil)
            return
        }
        let webView = WKWebView(frame: view.frame)
//        webView.scrollView.contentInset = UIEdgeInsets(top: 64, left: 0, bottom: 0, right: 0)
        webView.loadRequest(NSURLRequest(URL: newsItem.url))
        
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        
        
        
        webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        webView.topAnchor.constraintEqualToAnchor(topLayoutGuide.topAnchor).active = true
        
        
        view.startActivityIndicator()
    }
}
