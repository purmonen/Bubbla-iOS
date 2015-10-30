import UIKit
import WebKit
import SafariServices

class NewsViewController: UIViewController, WKNavigationDelegate {

    var newsItem: BubblaNews!
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.view.stopActivityIndicator()
        }
    }
    
    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        NSOperationQueue.mainQueue().addOperationWithBlock {
            self.view.stopActivityIndicator()
            self.view.showMessageLabel(error.localizedDescription)
            webView.hidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if newsItem == nil {
            navigationItem.rightBarButtonItem = nil
            self.view.showMessageLabel("Ingen nyhet vald")
            return
        }
        title = newsItem.domain
        let webView = WKWebView(frame: view.frame)
        webView.loadRequest(NSURLRequest(URL: newsItem.url))
        view.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsLinkPreview = true
        webView.allowsBackForwardNavigationGestures = true
        webView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor).active = true
        webView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor).active = true
        webView.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor).active = true
        webView.topAnchor.constraintEqualToAnchor(topLayoutGuide.topAnchor).active = true
        view.startActivityIndicator()
    }
    
    @IBAction func shareButtonClicked(sender: AnyObject) {
        let activityViewController = UIActivityViewController(activityItems: [newsItem.url], applicationActivities: nil)
        presentViewController(activityViewController, animated: true, completion: nil)
    }
}
