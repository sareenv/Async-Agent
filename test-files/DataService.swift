import Foundation

// MARK: - DataService
// This file demonstrates various continuation patterns and their appropriate use cases
//
// WORKFLOW ANALYSIS: Continuations and async/await patterns
// PRIORITY: Document best practices for continuation usage
// - Checked continuations: Use when wrapping callback APIs that need runtime safety
// - Unsafe continuations: Only for performance-critical paths with proven correctness
// - Avoid: Wrapping async code in continuations (unnecessary overhead)
//
// UPDATED: Added complex data pipeline for workflow analysis

class DataService {
    
    // MARK: - NEW: Complex Data Pipeline - DEMONSTRATES HIGH VALUE REFACTORING
    
    /// Multi-stage data processing pipeline with callbacks
    /// Classic example where async/await would significantly improve readability
    func syncDataPipeline(
        userId: String,
        completion: @escaping (Result<SyncResult, Error>) -> Void
    ) {
        // Stage 1: Fetch remote data
        fetchRemoteData(userId: userId) { remoteResult in
            switch remoteResult {
            case .success(let remoteData):
                // Stage 2: Fetch local cache
                self.fetchLocalCache(userId: userId) { localResult in
                    switch localResult {
                    case .success(let localData):
                        // Stage 3: Merge data
                        self.mergeData(remote: remoteData, local: localData) { mergeResult in
                            switch mergeResult {
                            case .success(let merged):
                                // Stage 4: Validate merged data
                                self.validateData(merged) { isValid in
                                    if isValid {
                                        // Stage 5: Save to cache
                                        self.saveToCache(merged, userId: userId) { saveResult in
                                            switch saveResult {
                                            case .success:
                                                // Stage 6: Notify observers
                                                self.notifyObservers(data: merged) { notifyResult in
                                                    switch notifyResult {
                                                    case .success:
                                                        let result = SyncResult(
                                                            itemCount: merged.items.count,
                                                            timestamp: Date()
                                                        )
                                                        completion(.success(result))
                                                    case .failure(let error):
                                                        // Don't fail sync if notification fails
                                                        let result = SyncResult(
                                                            itemCount: merged.items.count,
                                                            timestamp: Date()
                                                        )
                                                        completion(.success(result))
                                                    }
                                                }
                                            case .failure(let error):
                                                completion(.failure(error))
                                            }
                                        }
                                    } else {
                                        completion(.failure(DataError.validationFailed))
                                    }
                                }
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        // Proceed with remote data only
                        self.processRemoteOnly(remoteData, completion: completion)
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Helper methods for the pipeline
    private func fetchRemoteData(
        userId: String,
        completion: @escaping (Result<RemoteData, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.2)
            completion(.success(RemoteData(items: ["remote1", "remote2"])))
        }
    }
    
    private func fetchLocalCache(
        userId: String,
        completion: @escaping (Result<LocalData, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            completion(.success(LocalData(items: ["local1"])))
        }
    }
    
    private func mergeData(
        remote: RemoteData,
        local: LocalData,
        completion: @escaping (Result<MergedData, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            let merged = MergedData(items: remote.items + local.items)
            completion(.success(merged))
        }
    }
    
    private func validateData(
        _ data: MergedData,
        completion: @escaping (Bool) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.05)
            completion(true)
        }
    }
    
    private func saveToCache(
        _ data: MergedData,
        userId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.1)
            completion(.success(()))
        }
    }
    
    private func notifyObservers(
        data: MergedData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        DispatchQueue.global().async {
            Thread.sleep(forTimeInterval: 0.05)
            completion(.success(()))
        }
    }
    
    private func processRemoteOnly(
        _ data: RemoteData,
        completion: @escaping (Result<SyncResult, Error>) -> Void
    ) {
        let result = SyncResult(itemCount: data.items.count, timestamp: Date())
        completion(.success(result))
    }
    
    // MARK: - Original Examples
    
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
    
 NEW ANALYSIS FOR syncDataPipeline:
 - 6 levels of nested callbacks (callback hell)
 - 7 completion handler methods
 - Complex error handling with early returns
 - Perfect candidate for async/await sequential operations
 - Would reduce from ~60 lines to ~20 lines with async/await
 - Error propagation would be automatic with throws
 */

// MARK: - Supporting Types for Complex Pipeline

struct RemoteData {
    let items: [String]
}

struct LocalData {
    let items: [String]
}

struct MergedData {
    let items: [String]
}

struct SyncResult {
    let itemCount: Int
    let timestamp: Date
}
