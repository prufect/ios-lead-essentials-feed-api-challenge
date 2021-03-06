//
//  Copyright © 2018 Essential Developer. All rights reserved.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
	private let url: URL
	private let client: HTTPClient
	
	public enum Error: Swift.Error {
		case connectivity
		case invalidData
	}
		
	public init(url: URL, client: HTTPClient) {
		self.url = url
		self.client = client
	}
	
	public func load(completion: @escaping (FeedLoader.Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            
            switch result {
            case let .success((data, response)):
                guard
                    response.statusCode == 200,
                    let root = try? JSONDecoder().decode(Root.self, from: data)
                else { completion(.failure(Error.invalidData)); return }
                completion(.success(root.imageItems))
            default:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private struct Root: Decodable {
        let items: [Item]
        var imageItems: [FeedImage] {
            items.map { $0.image }
        }
    }
    
    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let url: URL
        
        private enum CodingKeys: String, CodingKey {
            case id = "image_id"
            case description = "image_desc"
            case location = "image_loc"
            case url = "image_url"
        }
        
        var image: FeedImage {
            FeedImage(id: id, description: description, location: location, url: url)
        }
    }
}
