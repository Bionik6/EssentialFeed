import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
  
  func load() {
    HTTPClient.shared.requestedURL = URL(string: "toto.com")
  }
}

class HTTPClient {
  var requestedURL: URL?
  
  static let shared = HTTPClient()
  
  private init() { }
}



final class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_does_not_request_data_from_url () {
    let client = HTTPClient.shared
    _ = RemoteFeedLoader()
    
    XCTAssertNil(client.requestedURL)
  }
  
  func test_load_request_dataFromURL() {
    let client = HTTPClient.shared
    let sut = RemoteFeedLoader()
    
    sut.load()
    
    XCTAssertNotNil(client.requestedURL)
  }
   
}
