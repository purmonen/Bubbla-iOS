import XCTest


class BubblaTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    func testBubblaNews() {
        var news1 = BubblaNews(title: "", url: NSURL(string: "http://google.com")!, publicationDate: NSDate(), category: .Recent, id: 0)
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
                let data = NSData(contentsOfURL: NSBundle(forClass: self.dynamicType).URLForResource("varlden", withExtension: "")!)!
                callback(.Success(data))
            }
        }
        
        let expectation = expectationWithDescription("Url Service")
        
        _BubblaApi(urlService: MockUrlService()).newsForCategory(.World) {
            if case .Success(let bubblaNewsItems) = $0 {
                XCTAssert(bubblaNewsItems.count == 50)
                let firstItem = bubblaNewsItems[0]
                XCTAssert(firstItem.title == "Ryskt stridsflygplan vid syriska gränsen uppges ha skjutits ned av turkiskt jaktflyg")
                XCTAssert(firstItem.category == .World)
                XCTAssert(firstItem.url.absoluteString == "http://cornucopia.cornubot.se/2015/11/flash-turkiet-har-skjutit-ner.html")
                XCTAssert(firstItem.id == 203038)
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
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
