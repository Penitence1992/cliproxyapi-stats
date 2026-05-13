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

        let outputCollector = DataCollector()
        let outputDelegate = PipeDelegate(pipe: outputPipe, handler: outputCollector.append)
        let errorDelegate = PipeDelegate(pipe: errorPipe) { _ in }

        try process.run()
        outputDelegate.wait()
        errorDelegate.wait()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw RemoteServiceError.httpError(Int(process.terminationStatus))
        }

        let outputData = outputCollector.data
        guard !outputData.isEmpty else {
            throw RemoteServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(RemoteResponse.self, from: outputData)
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
        case .invalidResponse: return "Empty response"
        case .httpError(let code): return "curl exit \(code)"
        case .parseError(let msg): return "Parse error: \(msg)"
        }
    }
}

private class PipeDelegate: NSObject, @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let handler: @Sendable (Data) -> Void

    init(pipe: Pipe, handler: @escaping @Sendable (Data) -> Void) {
        self.handler = handler
        super.init()
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                self?.semaphore.signal()
            } else {
                handler(data)
            }
        }
    }

    func wait() { semaphore.wait() }
}

private final class DataCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = Data()

    func append(_ data: Data) {
        lock.lock()
        buffer.append(data)
        lock.unlock()
    }

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }
}
