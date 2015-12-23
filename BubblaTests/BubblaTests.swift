import XCTest
@testable import Bubbla

extension String: SearchableListProtocol {
    var textToBeSearched: String { return self }
}

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
            if case .Success(let newsItems) = $0 {
                XCTAssert(newsItems.count == 5)
                let firstItem = newsItems[0]
                XCTAssert(firstItem.title == "Länsstyrelsen stoppar byggandet av 520 lägenheter i Hjorthagen, risk för störande buller från Värtabanan")
                XCTAssert(firstItem.category == "Sverige")
                XCTAssert(firstItem.url == NSURL(string: "http://mitti.se/520-lagenheter-stoppas/"))
                XCTAssert(firstItem.id == 204375)
                XCTAssert(firstItem.ogImageUrl == NSURL(string: "http://images.mitti.se/np/178395/512"))
                XCTAssert(firstItem.domain == "mitti.se")
                
                
                let categories = BubblaNews.categoriesWithTypesFromNewsItems(newsItems)
                XCTAssert(categories.count == 2)
                XCTAssert(categories[0].categoryType == "Ämne")
                XCTAssert(categories[0].categories == ["Ekonomi", "Politik"])
                XCTAssert(categories[1].categoryType == "Geografiskt område")
                XCTAssert(categories[1].categories == ["Europa", "Sverige"])
                
                
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
    
    func testSearchableList() {
        let items = ["Apa banan clementine", "Mentolcigg banan och mammut"]
        let searchableList = SearchableList(items: items)
        XCTAssert(searchableList.count == 2)
        XCTAssert(searchableList[0] == items[0])
        
        searchableList.updateFilteredItemsToMatchSearchText("apa")
        XCTAssert(searchableList.count == 1)
        XCTAssert(searchableList[0] == items[0])
    
        searchableList.updateFilteredItemsToMatchSearchText("MAMMUT")
        XCTAssert(searchableList.count == 1)
        XCTAssert(searchableList[0] == items[1])
        
        searchableList.updateFilteredItemsToMatchSearchText("apa clementine")
        XCTAssert(searchableList.count == 1)
        
        searchableList.updateFilteredItemsToMatchSearchText("banan")
        XCTAssert(searchableList.count == 2)
        
        searchableList.updateFilteredItemsToMatchSearchText("ey yo")
        XCTAssert(searchableList.count == 0)
        
        
        let emptySearchableList = SearchableList<String>(items: [])
        XCTAssert(emptySearchableList.count == 0)
        emptySearchableList.updateFilteredItemsToMatchSearchText("ey yo")
        XCTAssert(emptySearchableList.count == 0)

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
}
