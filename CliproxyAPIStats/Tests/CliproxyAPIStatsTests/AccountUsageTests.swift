import Testing
@testable import CliproxyAPIStats

@Test("remote account identity remains unique when server ids collide")
func remoteAccountIdentityRemainsUniqueWhenServerIdsCollide() {
    let first = AccountUsage(remote: RemoteAccount(
        id: "shared",
        email: "a@example.com",
        type: "claude",
        planType: "plus",
        primaryUsedPercent: 10,
        primaryRemainingPercent: 90,
        secondaryUsedPercent: nil,
        secondaryRemainingPercent: nil,
        primaryResetAt: 0,
        primaryResetAfterSeconds: 300,
        secondaryResetAt: nil,
        secondaryResetAfterSeconds: nil,
        limitReached: false,
        status: "active",
        lastRefreshedAt: nil
    ))
    let second = AccountUsage(remote: RemoteAccount(
        id: "shared",
        email: "b@example.com",
        type: "claude",
        planType: "plus",
        primaryUsedPercent: 20,
        primaryRemainingPercent: 80,
        secondaryUsedPercent: nil,
        secondaryRemainingPercent: nil,
        primaryResetAt: 0,
        primaryResetAfterSeconds: 600,
        secondaryResetAt: nil,
        secondaryResetAfterSeconds: nil,
        limitReached: false,
        status: "active",
        lastRefreshedAt: nil
    ))

    #expect(Set([first.id, second.id]).count == 2)
}

@Test("remote account identity remains unique when email and type collide")
func remoteAccountIdentityRemainsUniqueWhenEmailAndTypeCollide() {
    let first = AccountUsage(remote: RemoteAccount(
        id: "remote-a",
        email: "same@example.com",
        type: "claude",
        planType: "plus",
        primaryUsedPercent: 10,
        primaryRemainingPercent: 90,
        secondaryUsedPercent: nil,
        secondaryRemainingPercent: nil,
        primaryResetAt: 0,
        primaryResetAfterSeconds: 300,
        secondaryResetAt: nil,
        secondaryResetAfterSeconds: nil,
        limitReached: false,
        status: "active",
        lastRefreshedAt: nil
    ))
    let second = AccountUsage(remote: RemoteAccount(
        id: "remote-b",
        email: "same@example.com",
        type: "claude",
        planType: "plus",
        primaryUsedPercent: 20,
        primaryRemainingPercent: 80,
        secondaryUsedPercent: nil,
        secondaryRemainingPercent: nil,
        primaryResetAt: 0,
        primaryResetAfterSeconds: 600,
        secondaryResetAt: nil,
        secondaryResetAfterSeconds: nil,
        limitReached: false,
        status: "active",
        lastRefreshedAt: nil
    ))

    #expect(Set([first.id, second.id]).count == 2)
}
