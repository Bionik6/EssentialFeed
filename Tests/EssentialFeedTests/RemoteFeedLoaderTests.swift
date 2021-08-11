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
    
    expect(sut, toCompleteWith: .failure(.connectivity), when: {
      let clientError = NSError(domain: "Test", code: 0)
      client.complete(with: clientError)
    })
  }
  
  func test_load_delivers_error_on_non_200_http_response() {
    let (sut, client) = makeSUT()
    
    let samples = [199, 201, 300, 400, 500]
    samples.enumerated().forEach { idx, code in
      expect(sut, toCompleteWith: .failure(.invalidData), when: {
        let json = makeItemsJSON([])
        client.complete(withStatusCode: code, data: json, at: idx)
      })
    }
  }
  
  func test_load_delivers_error_on_200_http_response_with_invalid_json() {
    let (sut, client) = makeSUT()
    
    expect(sut, toCompleteWith: .failure(.invalidData), when: {
      let invalidJSON = Data([1, 2, 3])
      client.complete(withStatusCode: 200, data: invalidJSON)
    })
  }
  
  func test_load_delivers_no_items_on_200_http_response_with_empty_json_list() {
    let (sut, client) = makeSUT()
    
    expect(sut, toCompleteWith: .success([]), when: {
      let emptyListJSON = makeItemsJSON([])
      client.complete(withStatusCode: 200, data: emptyListJSON)
    })
  }
  
  func test_load_delivers_with_items_on_200_http_response_with_json_items() {
    let (sut, client) = makeSUT()
    
    let item1 = makeItem(id: UUID(),
                         imageURL: URL(string: "http://a-url.com")!)
    
    let item2 = makeItem(id: UUID(),
                         description: "a description",
                         location: "a location",
                         imageURL: URL(string: "http://another-url.com")!)
    
    expect(sut, toCompleteWith: .success([item1.model, item2.model]), when: {
      let json = makeItemsJSON([item1.json, item2.json])
      client.complete(withStatusCode: 200, data: json)
    })
  }
  
  func test_load_does_not_delivers_result_after_sut_instance_has_been_deallocated() {
    let client = HTTPClientSpy()
    let url = URL(string: "a-url.com")!
    var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
    
    var capturedResults = [RemoteFeedLoader.Result]()
    sut?.load { capturedResults.append($0) }
    
    sut = nil
    client.complete(withStatusCode: 200, data: makeItemsJSON([]))
    
    XCTAssertTrue(capturedResults.isEmpty)
  }
  
  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-given-url")!,
                       file: StaticString = #file,
                       line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    let sut = RemoteFeedLoader(url: url, client: client)
    trackForMemoryLeaks(instance: sut, file: file, line: line)
    trackForMemoryLeaks(instance: client, file: file, line: line)
    return (sut, client)
  }
  
  private func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "The sut should be deallocated, potential memory leak", file: file, line: line)
    }
  }
  
  private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
    let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageURL.absoluteString
    ].reduce(into: [String:Any]()) { (acc, e) in
      if let value = e.value { acc[e.key] = value }
    }
    return (item, json)
  }
  
  private func makeItemsJSON(_ items: [[String: Any]]) -> Data {
    let jsonArray = ["items": items]
    return try! JSONSerialization.data(withJSONObject: jsonArray)
  }
  
  private func expect(_ sut: RemoteFeedLoader,
                      toCompleteWith result: RemoteFeedLoader.Result,
                      when action: () -> Void,
                      file: StaticString = #file,
                      line: UInt = #line) {
    var capturedResults = [RemoteFeedLoader.Result]()
    sut.load { capturedResults.append($0) }
    action()
    
    XCTAssertEqual(capturedResults, [result], file: file, line: line)
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
    
    func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
      let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
      messages[index].completion(.success(data, response))
    }
  }
  
}
