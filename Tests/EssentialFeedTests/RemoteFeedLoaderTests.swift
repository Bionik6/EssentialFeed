import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
  
  private let url: URL
  private let client: HTTPClient
  
  
  init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  func load() {
    client.get(from: url)
  }
}


protocol HTTPClient {
  func get(from url: URL)
}


class HTTPClientSpy: HTTPClient {
  var requestedURL: URL?
  
  func get(from url: URL) {
    requestedURL = url
  }
  
}


final class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_does_not_request_data_from_url () {
    let client = HTTPClientSpy()
    let url = URL(string: "https://a-given-url")!
    _ = RemoteFeedLoader(url: url, client: client)
    
    XCTAssertNil(client.requestedURL)
  }
  
  func test_load_request_dataFromURL() {
    let url = URL(string: "https://a-given-url")!
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    
    sut.load()
    
    XCTAssertEqual(client.requestedURL, url)
  }
   
}
