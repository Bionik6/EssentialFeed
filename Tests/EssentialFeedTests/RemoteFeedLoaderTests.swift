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
  
    expect(sut, toCompleteWithError: .connectivity) {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    }
  }
  
  func test_load_delivers_error_on_non_200_http_response() {
    let (sut, client) = makeSUT()
    
    let samples = [199, 201, 300, 400, 500]
    samples.enumerated().forEach { idx, code in
      expect(sut, toCompleteWithError: .invalidData) {
        client.complete(withStatusCode: code, at: idx)
      }
    }
  }
  
  func test_load_delivers_error_on_200_http_response_with_invalid_json() {
    let (sut, client) = makeSUT()
    
    expect(sut, toCompleteWithError: .invalidData) {
      let invalidJSON = Data([1, 2, 3])
      client.complete(withStatusCode: 200, data: invalidJSON)
    }
  }
  
  func test_load_delivers_no_items_on_200_http_response_with_empty_json_list() {
    let (sut, client) = makeSUT()
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load { capturedResults.append($0) }
    
    let emptyListJSON = Data("{\"items\": []}".utf8)
    client.complete(withStatusCode: 200, data: emptyListJSON)
    
    XCTAssertEqual(capturedResults, [(.success([]))])
  }
  
  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-given-url")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    return (sut, client)
  }
  
  private func expect(_ sut: RemoteFeedLoader,
                      toCompleteWithError error: RemoteFeedLoader.Error,
                      when action: () -> Void,
                      file: StaticString = #file,
                      line: UInt = #line) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load { capturedResults.append($0) }
    action()
    
    XCTAssertEqual(capturedResults, [.failure(error)], file: file, line: line)
  }
   
  private class HTTPClientSpy: HTTPClient {
    var requestedURLs: [URL] { return messages.map { $0.url } }
    private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
      messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
      messages[index].completion(.failure(error))
    }
    
    func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
      let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
      messages[index].completion(.success(data, response))
    }
  }
  
}
