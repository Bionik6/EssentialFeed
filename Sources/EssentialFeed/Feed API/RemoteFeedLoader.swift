import Foundation


public final class RemoteFeedLoader: FeedLoader {
  private let url: URL
  private let client: HTTPClient
  
  public enum Error: Swift.Error {
    case invalidData
    case connectivity
  }
  
  public typealias Result = LoadFeedResult<Error>
  
  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Result) -> ()) {
    client.get(from: url) { [weak self] result in
      if self == nil { return }
      switch result {
      case let .success(data, response):
        completion(FeedItemsMapper.map(data: data, response: response))
      case .failure:
        completion(.failure(.connectivity))
      }
    }
  }
  
}
