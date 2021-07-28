import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
  
}

class HTTPClient {
  var requestedURL: URL?
}

final class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_does_not_request_data_from_url () {
    let client = HTTPClient()
    _ = RemoteFeedLoader()
    
    XCTAssertNil(client.requestedURL)
  }
   
}
