import Foundation

actor UsageService {
    private let session: URLSession
    private let chatGPTBaseURL = "https://chatgpt.com/backend-api/wham/usage"
    private let claudeBaseURL = "https://api.anthropic.com/api/oauth/usage"
    private let timeoutInterval: TimeInterval = 10

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    func fetchUsage(for account: Account) async -> AccountUsage {
        if account.type.lowercased().contains("claude") {
            return await fetchClaudeUsage(for: account)
        }
        return await fetchChatGPTUsage(for: account)
    }

    private func fetchChatGPTUsage(for account: Account) async -> AccountUsage {
        guard let url = URL(string: chatGPTBaseURL) else {
            return AccountUsage(account: account, error: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = timeoutInterval
        request.httpShouldHandleCookies = false

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return AccountUsage(account: account, error: "Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                return AccountUsage(account: account, error: "HTTP \(httpResponse.statusCode)")
            }

            let usage = try JSONDecoder().decode(UsageResponse.self, from: data)
            return AccountUsage(account: account, usage: usage)
        } catch is URLError {
            return AccountUsage(account: account, error: "Network error")
        } catch is DecodingError {
            return AccountUsage(account: account, error: "Parse error")
        } catch {
            return AccountUsage(account: account, error: error.localizedDescription)
        }
    }

    private func fetchClaudeUsage(for account: Account) async -> AccountUsage {
        guard let url = URL(string: claudeBaseURL) else {
            return AccountUsage(account: account, error: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(account.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.timeoutInterval = timeoutInterval
        request.httpShouldHandleCookies = false

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                return AccountUsage(account: account, error: "Invalid response")
            }

            guard httpResponse.statusCode == 200 else {
                return AccountUsage(account: account, error: "HTTP \(httpResponse.statusCode)")
            }

            let usage = try JSONDecoder().decode(ClaudeUsageResponse.self, from: data)
            return AccountUsage(account: account, claudeUsage: usage)
        } catch is URLError {
            return AccountUsage(account: account, error: "Network error")
        } catch is DecodingError {
            return AccountUsage(account: account, error: "Parse error")
        } catch {
            return AccountUsage(account: account, error: error.localizedDescription)
        }
    }

    func fetchAllUsages(for accounts: [Account]) async -> [AccountUsage] {
        await withTaskGroup(of: AccountUsage.self) { group in
            for account in accounts {
                group.addTask {
                    await self.fetchUsage(for: account)
                }
            }

            var results: [AccountUsage] = []
            for await usage in group {
                results.append(usage)
            }
            return results
        }
    }
}
