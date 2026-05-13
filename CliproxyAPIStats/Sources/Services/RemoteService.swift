import Foundation

actor RemoteService {
    func fetch(url urlString: String) async throws -> RemoteResponse {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        process.arguments = ["-s", "-m", "15", "--max-time", "15", urlString]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let errorMsg = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "curl exit \(process.terminationStatus)"
            throw RemoteServiceError.httpError(Int(process.terminationStatus), errorMsg)
        }

        guard !data.isEmpty else {
            throw RemoteServiceError.invalidResponse
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
    case httpError(Int, String)
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Empty response"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .parseError(let msg): return "Parse error: \(msg)"
        }
    }
}
