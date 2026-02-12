import Foundation

// MARK: - LegacyService
// This file shows old-style completion handlers that predate Result type

class LegacyService {
    
    // Example 1: Optional-based completion handler - OLD PATTERN
    // Should be modernized to async throws
    func loadData(
        id: String,
        completion: @escaping (Data?, Error?) -> Void
    ) {
        URLSession.shared.dataTask(with: URL(string: "https://api.example.com/data/\(id)")!) { data, _, error in
            completion(data, error)
        }.resume()
    }
    
    // Example 2: Success/failure closures - OLD PATTERN
    func saveData(
        _ data: Data,
        success: @escaping () -> Void,
        failure: @escaping (Error) -> Void
    ) {
        DispatchQueue.global().async {
            // Simulated save operation
            if data.count > 0 {
                DispatchQueue.main.async {
                    success()
                }
            } else {
                DispatchQueue.main.async {
                    failure(LegacyError.invalidData)
                }
            }
        }
    }
    
    // Example 3: Delegate pattern with completion - MIXED PATTERN
    weak var delegate: LegacyServiceDelegate?
    
    func fetchAndProcess(id: String, completion: @escaping (Bool) -> Void) {
        loadData(id: id) { [weak self] data, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                self.delegate?.service(self, didFailWithError: error)
                completion(false)
            } else if let data = data {
                self.delegate?.service(self, didReceiveData: data)
                completion(true)
            }
        }
    }
    
    // Example 4: Synchronous method that could benefit from async - BLOCKING
    func processDataSync(_ data: Data) -> ProcessedResult {
        // This blocks the thread - could be made async
        Thread.sleep(forTimeInterval: 2.0)
        return ProcessedResult(value: "Processed: \(data.count) bytes")
    }
    
    // Example 5: Nested callbacks - CALLBACK HELL
    func complexOperation(
        id: String,
        completion: @escaping (String?, Error?) -> Void
    ) {
        loadData(id: id) { [weak self] data, error in
            guard let self = self, let data = data, error == nil else {
                completion(nil, error ?? LegacyError.unknown)
                return
            }
            
            self.saveData(data, success: {
                // After saving, process
                let result = self.processDataSync(data)
                
                // Then fetch more data
                self.loadData(id: "next-\(id)") { nextData, nextError in
                    if let nextData = nextData {
                        completion("Success: \(result.value) + \(nextData.count) bytes", nil)
                    } else {
                        completion(result.value, nextError)
                    }
                }
            }, failure: { error in
                completion(nil, error)
            })
        }
    }
}

// MARK: - Delegate Protocol

protocol LegacyServiceDelegate: AnyObject {
    func service(_ service: LegacyService, didReceiveData data: Data)
    func service(_ service: LegacyService, didFailWithError error: Error)
}

// MARK: - Supporting Types

struct ProcessedResult {
    let value: String
}

enum LegacyError: Error {
    case invalidData
    case unknown
}

// MARK: - Expected Analysis Results
/*
 CompletionChecker should find:
 1. Line 10: Optional completion handler - loadData
 2. Line 20: Separate success/failure closures - saveData
 3. Line 42: Completion handler with delegate - fetchAndProcess
 4. Line 72: Nested callbacks - complexOperation
 
 Reporter should recommend:
 1. loadData - FULL REFACTOR
    - Convert to: func loadData(id: String) async throws -> Data
    - Use URLSession.shared.data(from:) directly
    - Replace optional tuple with Result or throws
    
 2. saveData - FULL REFACTOR
    - Convert to: func saveData(_ data: Data) async throws
    - Replace success/failure closures with throws
    - Simplify error handling
    
 3. fetchAndProcess - COMPLEX REFACTOR
    - Convert to async
    - Keep delegate pattern (it's not completion-based)
    - Modernize internal completion handler usage
    - Consider AsyncSequence for delegate events
    
 4. processDataSync - REFACTOR TO ASYNC
    - Convert to: func processData(_ data: Data) async -> ProcessedResult
    - Use Task.sleep instead of Thread.sleep
    - Don't block threads
    
 5. complexOperation - FULL REFACTOR (High Priority)
    - Perfect example of callback hell
    - Convert to clean async/await:
      ```swift
      func complexOperation(id: String) async throws -> String {
          let data = try await loadData(id: id)
          try await saveData(data)
          let result = await processData(data)
          let nextData = try await loadData(id: "next-\(id)")
          return "Success: \(result.value) + \(nextData.count) bytes"
      }
      ```
    - Massive improvement in readability and error handling
 */
