import Foundation

// MARK: - DataService
// This file demonstrates various continuation patterns and their appropriate use cases
//
// WORKFLOW ANALYSIS: Continuations and async/await patterns
// PRIORITY: Document best practices for continuation usage
// - Checked continuations: Use when wrapping callback APIs that need runtime safety
// - Unsafe continuations: Only for performance-critical paths with proven correctness
// - Avoid: Wrapping async code in continuations (unnecessary overhead)

class DataService {
    
    // Example 1: Checked continuation - APPROPRIATE USE
    // Wrapping a third-party callback-based API (simulated)
    func loadFromThirdPartySDK(id: String) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            // Simulating third-party SDK that only provides callbacks
            ThirdPartySDK.shared.fetch(resourceId: id) { data, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: DataError.noData)
                }
            }
        }
    }
    
    // Example 2: Unsafe continuation - SHOULD BE CHECKED
    // Using unsafe without clear performance justification
    func loadDataUnsafe(id: String) async -> Data? {
        await withUnsafeContinuation { continuation in
            // This should probably be withCheckedContinuation
            fetchData(id: id) { data in
                continuation.resume(returning: data)
            }
        }
    }
    
    // Example 3: Checked continuation - CAN BE REFACTORED
    // Wrapping our own async method (unnecessary)
    func processData(id: String) async throws -> ProcessedData {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let data = try await self.loadFromThirdPartySDK(id: id)
                    let processed = try self.process(data)
                    continuation.resume(returning: processed)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // Example 4: Proper async implementation - KEEP AS IS
    func processDataModern(id: String) async throws -> ProcessedData {
        let data = try await loadFromThirdPartySDK(id: id)
        return try process(data)
    }
    
    // Example 5: Nested continuations - ANTI-PATTERN
    func loadAndProcessNested(id: String) async throws -> ProcessedData {
        try await withCheckedThrowingContinuation { outerContinuation in
            Task {
                do {
                    let data = try await withCheckedThrowingContinuation { innerContinuation in
                        ThirdPartySDK.shared.fetch(resourceId: id) { data, error in
                            if let error = error {
                                innerContinuation.resume(throwing: error)
                            } else if let data = data {
                                innerContinuation.resume(returning: data)
                            }
                        }
                    }
                    let processed = try self.process(data)
                    outerContinuation.resume(returning: processed)
                } catch {
                    outerContinuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Private helpers
    
    private func fetchData(id: String, completion: @escaping (Data?) -> Void) {
        // Simulated callback-based method
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            completion(Data([1, 2, 3]))
        }
    }
    
    private func process(_ data: Data) throws -> ProcessedData {
        // Simulated processing
        return ProcessedData(value: "Processed")
    }
}

// MARK: - Supporting Types

struct ProcessedData {
    let value: String
}

enum DataError: Error {
    case noData
    case processingFailed
}

// Simulated third-party SDK
class ThirdPartySDK {
    static let shared = ThirdPartySDK()
    
    func fetch(resourceId: String, completion: @escaping (Data?, Error?) -> Void) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            completion(Data([1, 2, 3]), nil)
        }
    }
}

// MARK: - Expected Analysis Results
/*
 CompletionChecker should find:
 1. Line 11: withCheckedThrowingContinuation - loadFromThirdPartySDK
 2. Line 27: withUnsafeContinuation - loadDataUnsafe  
 3. Line 38: withCheckedThrowingContinuation - processData
 4. Line 63: withCheckedThrowingContinuation (nested) - loadAndProcessNested
 5. Line 86: Completion handler - fetchData(id:completion:)
 
 Reporter should recommend:
 1. loadFromThirdPartySDK - PRESERVE AS IS
    - Appropriate use: wrapping third-party callback API
    - No alternative available
    
 2. loadDataUnsafe - REFACTOR TO CHECKED
    - Change withUnsafeContinuation to withCheckedContinuation
    - No performance justification for unsafe variant
    
 3. processData - FULL REFACTOR
    - Remove continuation wrapper entirely
    - Use direct async/await as in processDataModern
    
 4. loadAndProcessNested - FULL REFACTOR
    - Eliminate nested continuations
    - Follow the pattern in processDataModern
    - Much simpler and clearer code
    
 5. fetchData - Consider refactoring to async if it's our code
 */
