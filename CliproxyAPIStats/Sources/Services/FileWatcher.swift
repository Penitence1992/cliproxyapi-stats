import Foundation

final class FileWatcher: Sendable {
    private let path: String
    private let callback: @Sendable () -> Void
    private let source: DispatchSourceFileSystemObject
    private let fileDescriptor: Int32
    private let queue: DispatchQueue

    init?(path: String, callback: @escaping @Sendable () -> Void) {
        let expandedPath = NSString(string: path).expandingTildeInPath
        self.path = expandedPath
        self.callback = callback
        self.queue = DispatchQueue(label: "com.cliproxyapi-stats.filewatcher", qos: .utility)

        // Ensure directory exists
        if !FileManager.default.fileExists(atPath: expandedPath) {
            try? FileManager.default.createDirectory(
                atPath: expandedPath,
                withIntermediateDirectories: true
            )
        }

        self.fileDescriptor = open(expandedPath, O_EVTONLY)
        guard fileDescriptor >= 0 else { return nil }

        self.source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: queue
        )

        source.setEventHandler { [callback] in
            callback()
        }

        source.setCancelHandler { [fileDescriptor] in
            close(fileDescriptor)
        }
    }

    func start() {
        source.resume()
    }

    func stop() {
        source.cancel()
    }

    deinit {
        source.cancel()
    }
}
