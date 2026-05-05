import Foundation

struct Account: Codable, Identifiable, Sendable {
    let accessToken: String
    let accountId: String?
    let disabled: Bool?
    let email: String
    let expired: String?
    let idToken: String
    let lastRefresh: String
    let refreshToken: String
    let type: String

    var id: String { accountId ?? email }

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
        guard !(disabled ?? false) else { return false }
        guard let expiredStr = expired,
              let expiredDate = DateParsing.parseDate(expiredStr) else {
            return true  // 没有过期时间则视为有效
        }
        return expiredDate > Date()
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
