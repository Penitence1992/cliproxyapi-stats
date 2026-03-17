import Foundation

struct AccountLoader: Sendable {
    func loadAccounts(from directoryPath: String) -> [Account] {
        let expandedPath = NSString(string: directoryPath).expandingTildeInPath
        let directoryURL = URL(fileURLWithPath: expandedPath)
        let fm = FileManager.default

        guard fm.fileExists(atPath: expandedPath) else {
            return []
        }

        let jsonFiles: [URL]
        do {
            jsonFiles = try fm.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            ).filter { $0.pathExtension == "json" }
        } catch {
            return []
        }

        let decoder = JSONDecoder()
        var accounts: [Account] = []

        for fileURL in jsonFiles {
            do {
                let data = try Data(contentsOf: fileURL)
                let account = try decoder.decode(Account.self, from: data)
                if account.isValid {
                    accounts.append(account)
                }
            } catch {
                // Skip invalid JSON files silently
                continue
            }
        }

        return accounts
    }
}
