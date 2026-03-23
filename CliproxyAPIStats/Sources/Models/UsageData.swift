import Foundation

struct UsageResponse: Codable, Sendable {
    let userId: String?
    let accountId: String?
    let email: String?
    let planType: String
    let rateLimit: RateLimit
    let codeReviewRateLimit: RateLimit?
    let credits: Credits?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case accountId = "account_id"
        case email
        case planType = "plan_type"
        case rateLimit = "rate_limit"
        case codeReviewRateLimit = "code_review_rate_limit"
        case credits
    }
}

struct RateLimit: Codable, Sendable {
    let allowed: Bool
    let limitReached: Bool
    let primaryWindow: WindowInfo
    let secondaryWindow: WindowInfo?

    enum CodingKeys: String, CodingKey {
        case allowed
        case limitReached = "limit_reached"
        case primaryWindow = "primary_window"
        case secondaryWindow = "secondary_window"
    }
}

struct WindowInfo: Codable, Sendable {
    let usedPercent: Int
    let limitWindowSeconds: Int
    let resetAfterSeconds: Int
    let resetAt: Int

    enum CodingKeys: String, CodingKey {
        case usedPercent = "used_percent"
        case limitWindowSeconds = "limit_window_seconds"
        case resetAfterSeconds = "reset_after_seconds"
        case resetAt = "reset_at"
    }

    var resetDate: Date {
        Date(timeIntervalSince1970: TimeInterval(resetAt))
    }

    var remainingPercent: Int {
        100 - usedPercent
    }

    var formattedResetTime: String {
        let seconds = resetAfterSeconds
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60

        if days > 0 {
            return "\(days)d\(hours)h"
        } else if hours > 0 {
            return "\(hours)h\(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct Credits: Codable, Sendable {
    let hasCredits: Bool
    let unlimited: Bool

    enum CodingKeys: String, CodingKey {
        case hasCredits = "has_credits"
        case unlimited
    }
}

// MARK: - Claude OAuth Usage

struct ClaudeWindowInfo: Codable, Sendable {
    let utilization: Double
    let resetsAt: String

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }

    var usedPercent: Int { Int(utilization.rounded()) }

    var formattedResetTime: String {
        guard let resetDate = DateParsing.parseDate(resetsAt) else { return "-" }
        let seconds = Int(resetDate.timeIntervalSinceNow)
        guard seconds > 0 else { return "0m" }
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days)d\(hours)h" }
        if hours > 0 { return "\(hours)h\(minutes)m" }
        return "\(minutes)m"
    }
}

struct ClaudeUsageResponse: Codable, Sendable {
    let fiveHour: ClaudeWindowInfo?
    let sevenDay: ClaudeWindowInfo?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
    }
}
