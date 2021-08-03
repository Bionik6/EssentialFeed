import Foundation


public protocol HTTPClient {
  func get(from url: URL, completion: @escaping (Error?, HTTPURLResponse?) -> Void)
}


public final class RemoteFeedLoader {
  private let url: URL
  private let client: HTTPClient
  
  public enum Error: Swift.Error {
    case invalidData
    case connectivity
  }
  
  public init(url: URL, client: HTTPClient) {
    self.url = url
    self.client = client
  }
  
  public func load(completion: @escaping (Error) -> ()) {
    client.get(from: url) { error, response in
      completion(response != nil ? .invalidData : .connectivity)
    }
  }
}
 
