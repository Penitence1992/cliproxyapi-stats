import Foundation

actor RemoteService {
    private var session: URLSession

    init() {
        self.session = URLSession(configuration: Self.makeConfig())
    }

    private static func makeConfig() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        return config
    }

    func fetch(url urlString: String) async throws -> RemoteResponse {
        guard let url = URL(string: urlString) else {
            throw RemoteServiceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.httpShouldHandleCookies = false

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RemoteServiceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw RemoteServiceError.httpError(httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(RemoteResponse.self, from: data)
        } catch {
            throw RemoteServiceError.parseError(error.localizedDescription)
        }
    }
}

enum RemoteServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .httpError(let code): return "HTTP \(code)"
        case .parseError(let msg): return "Parse error: \(msg)"
        }
    }
}
