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
    
    sut.load { _ in }
    
    XCTAssertEqual(client.requestedURLs, [url])
  }
  
  func test_load_twice_requests_data_from_url_twice() {
    let url = URL(string: "https://a-given-url")!
    let (sut, client) = makeSUT(url: url)
    
    sut.load { _ in }
    sut.load { _ in }
    
    XCTAssertEqual(client.requestedURLs, [url, url])
  }
  
  func test_load_delivers_error_on_client_error() {
    let (sut, client) = makeSUT()
    
    let clientError = NSError(domain: "Test", code: 0)
    var capturedErrors: [RemoteFeedLoader.Error] = []
    sut.load { capturedErrors.append($0) }
    client.complete(with: clientError)
    
    XCTAssertEqual(capturedErrors, [.connectivity])
  }
  
  func test_load_delivers_error_on_non_200_http_response() {
    let (sut, client) = makeSUT()
    
    let samples = [199, 201, 300, 400, 500]
    
    samples.enumerated().forEach { idx, code in
      var capturedErrors: [RemoteFeedLoader.Error] = []
      sut.load { capturedErrors.append($0) }
      client.complete(withStatusCode: code, at: idx)
      XCTAssertEqual(capturedErrors, [.invalidData])
    }
  }
  
  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-given-url")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }
   
  private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] { return messages.map { $0.url } }
    private var messages = [(url: URL, completion: (Error?, HTTPURLResponse?) -> Void)]()
    
    func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void) {
      messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
      messages[index].completion(error, nil)
    }
    
    func complete(withStatusCode code: Int, at index: Int = 0) {
      let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)
      messages[index].completion(nil, response)
    }
    
  }
}
