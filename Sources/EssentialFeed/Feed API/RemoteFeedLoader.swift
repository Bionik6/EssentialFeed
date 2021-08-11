import Foundation

public enum HTTPClientResult {
  case success(Data, HTTPURLResponse)
  case failure(Error)
}

public protocol HTTPClient {
  func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}


public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient
  
  public enum Error: Swift.Error {
    case invalidData
    case connectivity
  }
  
  public enum Result: Equatable {
    case success([FeedItem])
    case failure(Error)
  }
  
  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Result) -> ()) {
    client.get(from: url) { result in
      switch result {
      case let .success(data, _):
        if let root = try? JSONDecoder().decode(Root.self, from: data) {
          completion(.success(root.items))
        } else {
          completion(.failure(.invalidData))
        }
      case .failure: completion(.failure(.connectivity))
      }
    }
  }
}

private struct Root: Decodable {
  private(set) var items: [FeedItem]
}
