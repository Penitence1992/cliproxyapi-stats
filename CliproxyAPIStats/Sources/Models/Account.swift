import Foundation

struct Account: Codable, Identifiable, Sendable {
    let accessToken: String
    let accountId: String
    let disabled: Bool
    let email: String
    let expired: String
    let idToken: String
    let lastRefresh: String
    let refreshToken: String
    let type: String

    var id: String { accountId }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case accountId = "account_id"
        case disabled
        case email
        case expired
        case idToken = "id_token"
        case lastRefresh = "last_refresh"
        case refreshToken = "refresh_token"
        case type
    }

    var isValid: Bool {
        guard !disabled else { return false }
        guard let expiredDate = DateParsing.parseDate(expired) else {
            return false
        }
        return expiredDate > Date()
    }

    var maskedEmail: String {
        let parts = email.split(separator: "@")
        guard parts.count == 2 else { return email }
        let name = String(parts[0])
        let domain = String(parts[1])
        if name.count <= 4 {
            return "\(name)***@\(domain)"
        }
        let prefix = name.prefix(4)
        return "\(prefix)***@\(domain)"
    }
}

enum DateParsing {
    nonisolated(unsafe) static let flexible: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) static let standard: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parseDate(_ dateString: String) -> Date? {
        flexible.date(from: dateString)
            ?? standard.date(from: dateString)
    }
}
