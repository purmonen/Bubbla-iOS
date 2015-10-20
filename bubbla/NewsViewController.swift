//
//  NewsViewController.swift
//  bubbla
//
//  Created by Sami Purmonen on 20/10/15.
//  Copyright © 2015 Sami Purmonen. All rights reserved.
//

import UIKit

class NewsViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    
    var newsItem: _BubblaApi.NewsItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.loadRequest(NSURLRequest(URL: newsItem.url))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
