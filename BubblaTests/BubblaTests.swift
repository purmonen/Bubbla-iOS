import XCTest
@testable import Bubbla

class BubblaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testBubblaNews() {
        var news1 = BubblaNews(title: "", url: NSURL(string: "http://google.com")!, publicationDate: NSDate(), category: "Världen", categoryType: "Geografiskt område", id: 0, ogImageUrl: nil)
        assert(!news1.isRead)
        news1.isRead = true
        assert(news1.isRead)
        news1.isRead = false
        assert(!news1.isRead)
        assert(news1.domain == "google.com")
    }
    
    func testNewsFromServer() {
        
        class MockUrlService: UrlService {
            func dataFromUrl(url: NSURL, callback: Response<NSData> -> Void) {
                let data = NSData(contentsOfURL: NSBundle(forClass: self.dynamicType).URLForResource("news", withExtension: "json")!)!
                callback(.Success(data))
            }
        }
        
        let expectation = expectationWithDescription("Url Service")
        
        _BubblaApi(urlService: MockUrlService()).newsForCategory(nil) {
            if case .Success(let bubblaNewsItems) = $0 {
                XCTAssert(bubblaNewsItems.count == 5)
                let firstItem = bubblaNewsItems[0]
                XCTAssert(firstItem.title == "Länsstyrelsen stoppar byggandet av 520 lägenheter i Hjorthagen, risk för störande buller från Värtabanan")
                XCTAssert(firstItem.category == "Sverige")
                XCTAssert(firstItem.url == NSURL(string: "http://mitti.se/520-lagenheter-stoppas/"))
                XCTAssert(firstItem.id == 204375)
                XCTAssert(firstItem.ogImageUrl == NSURL(string: "http://images.mitti.se/np/178395/512"))
                XCTAssert(firstItem.domain == "mitti.se")
            } else {
                XCTAssert(false)
            }
            expectation.fulfill()
        }
        
        waitForExpectationsWithTimeout(5) {
            error in
            XCTAssertNil(error)
        }
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
