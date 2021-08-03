import XCTest
import EssentialFeed


final class RemoteFeedLoaderTests: XCTestCase {
  
  func test_init_does_not_request_data_from_url () {
    let (_, client) = makeSUT()
    
    XCTAssertTrue(client.requestedURLs.isEmpty)
  }
  
  func test_load_requests_data_from_url() {
    let url = URL(string: "https://a-given-url")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load()
    
    XCTAssertEqual(client.requestedURLs, [url])
  }
  
  func test_load_twice_requests_data_from_url_twice() {
    let url = URL(string: "https://a-given-url")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load()
    sut.load()
    
    XCTAssertEqual(client.requestedURLs, [url, url])
  }
  
  func test_load_delivers_error_on_client_error() {
    let (sut, client) = makeSUT()
    client.error = NSError(domain: "Test", code: 0)
    var capturedErrors: [RemoteFeedLoader.Error] = []
    
    sut.load { capturedErrors.append($0) }
    XCTAssertEqual(capturedErrors, [.connectivity])
  }
  
  
  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-given-url")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }
   
  private class HTTPClientSpy: HTTPClient {
    var requestedURL: URL?
    var requestedURLs = [URL]()
    var error: Error?
    
    func get(from url: URL, completion: @escaping (Error) -> Void) {
      if let error = error { completion(error) }
      requestedURLs.append(url)
    }
    
  }
}
