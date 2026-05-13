import Foundation

struct AccountUsage: Identifiable, Sendable {
    let id: String
    let email: String
    let type: String
    let planType: String
    let primaryUsedPercent: Int
    let secondaryUsedPercent: Int?
    let primaryResetTime: String
    let secondaryResetTime: String?
    let codeReviewUsedPercent: Int?
    let limitReached: Bool
    let error: String?
    let isLoading: Bool

    var primaryRemainingPercent: Int { 100 - primaryUsedPercent }
    var secondaryRemainingPercent: Int? {
        secondaryUsedPercent.map { 100 - $0 }
    }
    var isFreePlan: Bool {
        planType.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "free"
    }
    var isSuspectedBanned: Bool {
        error == "HTTP 401" || error == "suspected_banned"
    }

    init(account: Account, usage: UsageResponse) {
        self.id = "\(account.email)|\(account.type)"
        self.email = account.email
        self.type = account.type
        self.planType = usage.planType
        self.primaryUsedPercent = usage.rateLimit.primaryWindow.usedPercent
        self.secondaryUsedPercent = usage.rateLimit.secondaryWindow?.usedPercent
        self.primaryResetTime = usage.rateLimit.primaryWindow.formattedResetTime
        self.secondaryResetTime = usage.rateLimit.secondaryWindow?.formattedResetTime
        self.codeReviewUsedPercent = usage.codeReviewRateLimit?.primaryWindow.usedPercent
        self.limitReached = usage.rateLimit.limitReached
        self.error = nil
        self.isLoading = false
    }

    init(account: Account, claudeUsage: ClaudeUsageResponse) {
        self.id = "\(account.email)|\(account.type)"
        self.email = account.email
        self.type = account.type
        self.planType = "claude"
        self.primaryUsedPercent = claudeUsage.fiveHour?.usedPercent ?? 0
        self.secondaryUsedPercent = claudeUsage.sevenDay?.usedPercent
        self.primaryResetTime = claudeUsage.fiveHour?.formattedResetTime ?? "-"
        self.secondaryResetTime = claudeUsage.sevenDay?.formattedResetTime
        self.codeReviewUsedPercent = nil
        self.limitReached = (claudeUsage.fiveHour?.usedPercent ?? 0) >= 100
        self.error = nil
        self.isLoading = false
    }

    init(account: Account, error: String) {
        self.id = "\(account.email)|\(account.type)"
        self.email = account.email
        self.type = account.type
        self.planType = "unknown"
        self.primaryUsedPercent = 0
        self.secondaryUsedPercent = nil
        self.primaryResetTime = "-"
        self.secondaryResetTime = nil
        self.codeReviewUsedPercent = nil
        self.limitReached = false
        self.error = error
        self.isLoading = false
    }

    init(loadingFrom account: Account) {
        self.id = "\(account.email)|\(account.type)"
        self.email = account.email
        self.type = account.type
        self.planType = ""
        self.primaryUsedPercent = 0
        self.secondaryUsedPercent = nil
        self.primaryResetTime = ""
        self.secondaryResetTime = nil
        self.codeReviewUsedPercent = nil
        self.limitReached = false
        self.error = nil
        self.isLoading = true
    }

    init(remote: RemoteAccount) {
        self.id = remote.id
        self.email = remote.email
        self.type = remote.type
        self.planType = remote.planType
        self.primaryUsedPercent = remote.primaryUsedPercent
        self.secondaryUsedPercent = remote.secondaryUsedPercent
        self.primaryResetTime = Self.formatResetSeconds(remote.primaryResetAfterSeconds)
        self.secondaryResetTime = remote.secondaryResetAfterSeconds.map { Self.formatResetSeconds($0) }
        self.codeReviewUsedPercent = nil
        self.limitReached = remote.limitReached
        self.error = remote.status == "active" ? nil : remote.status
        self.isLoading = false
    }

    private static func formatResetSeconds(_ seconds: Int) -> String {
        let days = seconds / 86400
        let hours = (seconds % 86400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "\(days)d\(hours)h" }
        if hours > 0 { return "\(hours)h\(minutes)m" }
        return "\(minutes)m"
    }

    init(loadingId: String, email: String, type: String) {
        self.id = loadingId
        self.email = email
        self.type = type
        self.planType = ""
        self.primaryUsedPercent = 0
        self.secondaryUsedPercent = nil
        self.primaryResetTime = ""
        self.secondaryResetTime = nil
        self.codeReviewUsedPercent = nil
        self.limitReached = false
        self.error = nil
        self.isLoading = true
    }
}

struct GroupSummary: Identifiable, Sendable {
    let type: String
    let accountCount: Int
    let avgPrimaryRemaining: Int
    let avgSecondaryRemaining: Int?
    let categoryCounts: [(label: String, count: Int, color: String)]

    var id: String { type }

    init(remoteGroup: RemoteGroup) {
        self.type = remoteGroup.type
        self.accountCount = remoteGroup.accountCount
        self.avgPrimaryRemaining = remoteGroup.avgPrimaryRemainingPercent
        self.avgSecondaryRemaining = remoteGroup.avgSecondaryRemainingPercent
        self.categoryCounts = []
    }

    init(type: String, usages: [AccountUsage], weeklyExhaustedZeroes5H: Bool = true) {
        self.type = type
        self.accountCount = usages.count

        // Build category counts
        var counts: [String: Int] = [:]
        for usage in usages {
            if usage.isSuspectedBanned {
                counts["ban", default: 0] += 1
            } else if usage.isFreePlan {
                counts["free", default: 0] += 1
            } else {
                counts[usage.planType.lowercased(), default: 0] += 1
            }
        }
        let order = ["plus", "pro", "team", "lite", "free", "ban"]
        var cats: [(label: String, count: Int, color: String)] = []
        for key in order {
            if let c = counts[key] {
                cats.append((label: key, count: c, color: Self.colorForCategory(key)))
            }
        }
        for (key, c) in counts where !order.contains(key) {
            cats.append((label: key, count: c, color: "secondary"))
        }
        self.categoryCounts = cats

        let validUsages = usages.filter { $0.error == nil && !$0.isLoading }

        if validUsages.isEmpty {
            self.avgPrimaryRemaining = 0
            self.avgSecondaryRemaining = nil
        } else {
            let primaryValues = validUsages.map { usage -> Int in
                if weeklyExhaustedZeroes5H, (usage.secondaryRemainingPercent ?? 100) <= 0 {
                    return 0
                }
                return usage.primaryRemainingPercent
            }
            self.avgPrimaryRemaining = primaryValues.reduce(0, +) / primaryValues.count

            let secondaryValues = validUsages.compactMap(\.secondaryRemainingPercent)
            self.avgSecondaryRemaining = secondaryValues.isEmpty
                ? nil
                : secondaryValues.reduce(0, +) / secondaryValues.count
        }
    }

    private static func colorForCategory(_ cat: String) -> String {
        switch cat {
        case "plus", "team", "pro": return "blue"
        case "lite": return "orange"
        case "free": return "gray"
        case "ban": return "red"
        default: return "secondary"
        }
    }
}
