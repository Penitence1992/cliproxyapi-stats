import Foundation

struct RemoteResponse: Codable, Sendable {
    let accounts: [RemoteAccount]
    let groups: [RemoteGroup]
    let refresh: RemoteRefreshInfo
}

struct RemoteAccount: Codable, Sendable {
    let id: String
    let email: String
    let type: String
    let planType: String
    let primaryUsedPercent: Int
    let primaryRemainingPercent: Int
    let secondaryUsedPercent: Int?
    let secondaryRemainingPercent: Int?
    let primaryResetAt: Int
    let primaryResetAfterSeconds: Int
    let secondaryResetAt: Int?
    let secondaryResetAfterSeconds: Int?
    let limitReached: Bool
    let status: String
    let lastRefreshedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, type, status
        case planType = "plan_type"
        case primaryUsedPercent = "primary_used_percent"
        case primaryRemainingPercent = "primary_remaining_percent"
        case secondaryUsedPercent = "secondary_used_percent"
        case secondaryRemainingPercent = "secondary_remaining_percent"
        case primaryResetAt = "primary_reset_at"
        case primaryResetAfterSeconds = "primary_reset_after_seconds"
        case secondaryResetAt = "secondary_reset_at"
        case secondaryResetAfterSeconds = "secondary_reset_after_seconds"
        case limitReached = "limit_reached"
        case lastRefreshedAt = "last_refreshed_at"
    }
}

struct RemoteGroup: Codable, Sendable {
    let type: String
    let accountCount: Int
    let suspectedBannedCount: Int
    let avgPrimaryRemainingPercent: Int
    let avgSecondaryRemainingPercent: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case accountCount = "account_count"
        case suspectedBannedCount = "suspected_banned_count"
        case avgPrimaryRemainingPercent = "avg_primary_remaining_percent"
        case avgSecondaryRemainingPercent = "avg_secondary_remaining_percent"
    }
}

struct RemoteRefreshInfo: Codable, Sendable {
    let running: Bool
    let lastStartedAt: String?
    let lastFinishedAt: String?

    enum CodingKeys: String, CodingKey {
        case running
        case lastStartedAt = "last_started_at"
        case lastFinishedAt = "last_finished_at"
    }
}
