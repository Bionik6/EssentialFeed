import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
  
  func load() {
    HTTPClient.shared.get(from: URL(string: "toto.com")!)
  }
}


class HTTPClient {
  
  static var shared = HTTPClient()
  
  func get(from url: URL) { }
  
}


class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  
  override func get(from url: URL) {
    requestedURL = url
  }
  
}


final class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_does_not_request_data_from_url () {
    let client = HTTPClientSpy()
    HTTPClient.shared = client
    _ = RemoteFeedLoader()
    
    XCTAssertNil(client.requestedURL)
  }
  
  func test_load_request_dataFromURL() {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader()
    HTTPClient.shared = client
    
    sut.load()
    
    XCTAssertNotNil(client.requestedURL)
  }
   
}
