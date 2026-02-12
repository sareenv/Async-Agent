import Foundation
import UIKit

// MARK: - APIClient
// This file demonstrates Objective-C interoperability constraints
// Test: Trigger workflow analysis

class APIClient: NSObject {
    
    // Example 1: @objc method - MUST KEEP COMPLETION HANDLER
    // Objective-C doesn't support async/await, completion handler is required
    @objc func login(
        username: String,
        password: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        // Implementation
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.5)
            let user = User(id: "123", name: username)
            completion(.success(user))
        }
    }
    
    // Example 2: Async variant for Swift code - GOOD PATTERN
    // Keep @objc method above, add async variant for Swift
    func login(username: String, password: String) async throws -> User {
        try await withCheckedThrowingContinuation { continuation in
            login(username: username, password: password) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // Example 3: @objc with @IBAction - MUST PRESERVE SIGNATURE
    @IBAction @objc func refreshButtonTapped(_ sender: UIButton) {
        // This method signature is required for UIKit
        Task {
            await performRefresh()
        }
    }
    
    // Example 4: Protocol conformance requiring @objc - CONSTRAINED
    @objc func fetchUserProfile(
        userId: String,
        completion: @escaping (UserProfile?, Error?) -> Void
    ) {
        // Conforming to an @objc protocol requires completion handler
        Task {
            do {
                let profile = try await fetchUserProfileAsync(userId: userId)
                completion(profile, nil)
            } catch {
                completion(nil, error)
            }
        }
    }
    
    // Internal async implementation - CAN MODERNIZE
    private func fetchUserProfileAsync(userId: String) async throws -> UserProfile {
        // This is fine - internal async implementation
        try await withCheckedThrowingContinuation { continuation in
            // Simulated API call
            DispatchQueue.global().async {
                Thread.sleep(forTimeInterval: 0.3)
                let profile = UserProfile(userId: userId, email: "\(userId)@example.com")
                continuation.resume(returning: profile)
            }
        }
    }
    
    // Example 5: Pure Swift method - SHOULD BE REFACTORED
    // No @objc, not required by protocol, can be fully async
    func logout(completion: @escaping (Bool) -> Void) {
        // This can be converted to async
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.2)
            completion(true)
        }
    }
    
    // Example 6: Internal async helper - KEEP BUT COULD IMPROVE
    private func performRefresh() async {
        // This is fine but fetchUserProfileAsync could be improved
        do {
            let profile = try await fetchUserProfileAsync(userId: "current")
            print("Refreshed: \(profile)")
        } catch {
            print("Refresh failed: \(error)")
        }
    }
}

// MARK: - Protocol Conformance Example

@objc protocol UserServiceProtocol {
    func fetchUserProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void)
}

extension APIClient: UserServiceProtocol {
    // Already implemented above
}

// MARK: - Supporting Types

struct User {
    let id: String
    let name: String
}

struct UserProfile {
    let userId: String
    let email: String
}

// MARK: - Expected Analysis Results
/*
 CompletionChecker should find:
 1. Line 11: @objc completion handler - login(username:password:completion:)
 2. Line 26: withCheckedThrowingContinuation - login async variant
 3. Line 39: @IBAction @objc - refreshButtonTapped
 4. Line 46: @objc completion handler - fetchUserProfile
 5. Line 61: withCheckedThrowingContinuation - fetchUserProfileAsync
 6. Line 73: Completion handler - logout
 
 Reporter should recommend:
 1. login(username:password:completion:) - PRESERVE AS IS
    - @objc exposure requires completion handler
    - Recommendation: Keep both versions (completion for ObjC, async for Swift)
    - Current implementation is correct
    
 2. refreshButtonTapped - PRESERVE AS IS
    - @IBAction @objc required for UIKit
    - Internal async usage is appropriate
    
 3. fetchUserProfile - PARTIAL REFACTOR
    - @objc protocol requirement mandates completion handler
    - Keep @objc method with completion
    - Internal fetchUserProfileAsync can stay but should not use continuation
    - Should directly implement async logic without wrapping in continuation
    
 4. fetchUserProfileAsync - REFACTOR
    - Remove continuation wrapper
    - Implement actual async logic directly
    - This is wrapping synchronous code, not bridging callbacks
    
 5. logout - FULL REFACTOR
    - No @objc exposure
    - Convert to: func logout() async -> Bool
    - Remove completion handler entirely
 */
