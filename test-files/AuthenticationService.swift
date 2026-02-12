import Foundation
import UIKit

// MARK: - AuthenticationService
/// Complex authentication flow demonstrating real-world callback patterns
/// This service shows typical scenarios where async/await refactoring provides significant value

class AuthenticationService: NSObject {
    
    private let networkService = NetworkService()
    private let tokenManager = TokenManager()
    
    // MARK: - Nested Callbacks (Callback Hell) - HIGH PRIORITY REFACTOR
    
    /// Classic "pyramid of doom" - multiple nested asynchronous operations
    /// This is a prime candidate for async/await refactoring
    func authenticateUser(
        email: String,
        password: String,
        completion: @escaping (Result<User, AuthError>) -> Void
    ) {
        // Step 1: Validate credentials
        validateCredentials(email: email, password: password) { validationResult in
            switch validationResult {
            case .success:
                // Step 2: Login to get token
                self.performLogin(email: email, password: password) { loginResult in
                    switch loginResult {
                    case .success(let token):
                        // Step 3: Save token
                        self.tokenManager.saveToken(token) { saveResult in
                            switch saveResult {
                            case .success:
                                // Step 4: Fetch user profile
                                self.fetchUserProfile(token: token) { profileResult in
                                    switch profileResult {
                                    case .success(let user):
                                        // Step 5: Update analytics
                                        self.logAnalyticsEvent(event: "login_success", userId: user.id) { _ in
                                            completion(.success(user))
                                        }
                                    case .failure(let error):
                                        completion(.failure(.profileFetchFailed(error)))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(.tokenSaveFailed(error)))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(.loginFailed(error)))
                    }
                }
            case .failure(let error):
                completion(.failure(.validationFailed(error)))
            }
        }
    }
    
    // MARK: - Mixed Patterns - PARTIAL REFACTOR OPPORTUNITY
    
    /// Combines completion handlers with some modern patterns
    /// Shows opportunity for incremental modernization
    func refreshUserSession(
        userId: String,
        completion: @escaping (Result<Session, AuthError>) -> Void
    ) {
        // Old pattern: completion handler
        tokenManager.getStoredToken { tokenResult in
            guard let token = try? tokenResult.get() else {
                completion(.failure(.noToken))
                return
            }
            
            // Could use async/await here internally
            self.validateToken(token) { isValid in
                if isValid {
                    // Nested callback
                    self.fetchUserProfile(token: token) { profileResult in
                        switch profileResult {
                        case .success(let user):
                            let session = Session(user: user, token: token)
                            completion(.success(session))
                        case .failure(let error):
                            completion(.failure(.profileFetchFailed(error)))
                        }
                    }
                } else {
                    // Token expired, need to refresh
                    self.refreshToken(userId: userId) { refreshResult in
                        switch refreshResult {
                        case .success(let newToken):
                            self.fetchUserProfile(token: newToken) { profileResult in
                                switch profileResult {
                                case .success(let user):
                                    let session = Session(user: user, token: newToken)
                                    completion(.success(session))
                                case .failure(let error):
                                    completion(.failure(.profileFetchFailed(error)))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(.tokenRefreshFailed(error)))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Objective-C Interop - PRESERVE AS IS
    
    /// Required for Objective-C compatibility - CANNOT be refactored
    @objc func login(
        email: String,
        password: String,
        completion: @escaping (NSDictionary?, NSError?) -> Void
    ) {
        authenticateUser(email: email, password: password) { result in
            switch result {
            case .success(let user):
                let userDict: NSDictionary = [
                    "id": user.id,
                    "email": user.email,
                    "name": user.name
                ]
                completion(userDict, nil)
            case .failure(let error):
                completion(nil, error as NSError)
            }
        }
    }
    
    // MARK: - Delegate Pattern - CONSTRAINED
    
    /// UIKit delegate callback - signature constrained by framework
    @objc func textFieldDidEndEditing(_ textField: UITextField) {
        // This signature is required by UITextFieldDelegate
        // Internal implementation could use async/await with Task
        guard let email = textField.text else { return }
        
        Task {
            await validateEmailFormat(email)
        }
    }
    
    // MARK: - Error Handling Complexity - REFACTOR BENEFIT
    
    /// Complex error handling across multiple async operations
    /// async/await with do-catch would simplify this significantly
    func performSecureAction(
        action: String,
        completion: @escaping (Result<ActionResult, AuthError>) -> Void
    ) {
        // Get token with error handling
        tokenManager.getStoredToken { tokenResult in
            switch tokenResult {
            case .success(let token):
                // Validate token with error handling
                self.validateToken(token) { isValid in
                    if isValid {
                        // Perform action with error handling
                        self.executeAction(action, token: token) { actionResult in
                            switch actionResult {
                            case .success(let result):
                                // Log success with error handling
                                self.logActionSuccess(action: action) { logResult in
                                    // Ignore log failures, return action result
                                    _ = logResult
                                    completion(.success(result))
                                }
                            case .failure(let error):
                                // Log failure with error handling
                                self.logActionFailure(action: action, error: error) { logResult in
                                    // Ignore log failures, return action error
                                    _ = logResult
                                    completion(.failure(.actionFailed(error)))
                                }
                            }
                        }
                    } else {
                        completion(.failure(.invalidToken))
                    }
                }
            case .failure(let error):
                completion(.failure(.tokenRetrievalFailed(error)))
            }
        }
    }
    
    // MARK: - Helper Methods (All completion-based)
    
    private func validateCredentials(
        email: String,
        password: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            // Simulate validation
            Thread.sleep(forTimeInterval: 0.1)
            completion(.success(()))
        }
    }
    
    private func performLogin(
        email: String,
        password: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.2)
            completion(.success("mock_token_12345"))
        }
    }
    
    private func fetchUserProfile(
        token: String,
        completion: @escaping (Result<User, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.15)
            let user = User(id: "user_123", email: "test@example.com", name: "Test User")
            completion(.success(user))
        }
    }
    
    private func logAnalyticsEvent(
        event: String,
        userId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.05)
            completion(.success(()))
        }
    }
    
    private func validateToken(
        _ token: String,
        completion: @escaping (Bool) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            completion(!token.isEmpty)
        }
    }
    
    private func refreshToken(
        userId: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.2)
            completion(.success("refreshed_token_67890"))
        }
    }
    
    private func executeAction(
        _ action: String,
        token: String,
        completion: @escaping (Result<ActionResult, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.15)
            completion(.success(ActionResult(action: action, success: true)))
        }
    }
    
    private func logActionSuccess(
        action: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            completion(.success(()))
        }
    }
    
    private func logActionFailure(
        action: String,
        error: Error,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            completion(.success(()))
        }
    }
    
    private func validateEmailFormat(_ email: String) async {
        // Modern async implementation
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}

// MARK: - Supporting Types

struct User {
    let id: String
    let email: String
    let name: String
}

struct Session {
    let user: User
    let token: String
}

struct ActionResult {
    let action: String
    let success: Bool
}

enum AuthError: Error {
    case validationFailed(Error)
    case loginFailed(Error)
    case tokenSaveFailed(Error)
    case profileFetchFailed(Error)
    case noToken
    case invalidToken
    case tokenRefreshFailed(Error)
    case tokenRetrievalFailed(Error)
    case actionFailed(Error)
}

class TokenManager {
    func saveToken(_ token: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global().async {
            completion(.success(()))
        }
    }
    
    func getStoredToken(completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().async {
            completion(.success("stored_token"))
        }
    }
}

// MARK: - Expected Analysis
/*
 This file demonstrates HIGH VALUE refactoring opportunities:
 
 1. authenticateUser() - CRITICAL REFACTOR
    - Classic "callback hell" with 5 levels of nesting
    - Perfect candidate for async/await with sequential await statements
    - Would reduce complexity from O(n^2) nesting to O(n) sequential
    - Error handling would be simplified with do-catch
    
 2. refreshUserSession() - HIGH PRIORITY REFACTOR  
    - Multiple nested completion handlers
    - Complex branching logic that would benefit from early returns with await
    - Mixed validation and data fetching that async/await would clarify
    
 3. performSecureAction() - MODERATE REFACTOR
    - Deep nesting with error handling at each level
    - Would benefit from structured error propagation with throws
    
 4. login(@objc) - PRESERVE AS IS
    - Required for Objective-C interop
    - Recommendation: Keep this, refactor authenticateUser internally
    
 5. textFieldDidEndEditing - PRESERVE SIGNATURE
    - UIKit delegate requirement
    - Already uses Task for async work (good pattern)
    
 The workflow should detect:
 - 20+ completion handlers
 - 15+ @escaping closures  
 - Multiple levels of callback nesting
 - Mix of refactorable and non-refactorable code
 */
