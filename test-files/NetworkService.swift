import Foundation

// MARK: - NetworkService
// WORKFLOW ANALYSIS: Completion handler patterns for network operations
// PRIORITY: Evaluate candidates for async/await modernization
// Consider: URLSession now has native async/await support (iOS 15+)
// This file contains examples of completion handlers that could be refactored to async/await
//
// TEST PR: Adding new methods to verify workflow analysis on pull requests

class NetworkService {
    
    // NEW: Test method added for PR workflow validation
    func uploadFile(
        _ fileURL: URL,
        to destination: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Legacy completion handler pattern - candidate for async/await refactoring
        let task = URLSession.shared.uploadTask(with: URLRequest(url: destination), fromFile: fileURL) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }
            completion(.success(responseString))
        }
        task.resume()
    }
    
    // Example 1: Completion handler with Result type - SHOULD BE REFACTORED
    // This uses withCheckedThrowingContinuation but URLSession already supports async/await
    func fetchData(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            } else if let data = data {
                completion(.success(data))
            } else {
                completion(.failure(NetworkError.noData))
            }
        }.resume()
    }
    
    // Example 2: Async wrapper using continuation - CAN BE REMOVED
    // URLSession.data(for:) already exists, this wrapper is unnecessary
    func fetchData(from url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            fetchData(from: url) { result in
                continuation.resume(with: result)
            }
        }
    }
    
    // Example 3: Completion handler with simple callback - SHOULD BE REFACTORED
    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil)
                return
            }
            completion(image)
        }.resume()
    }
    
    // Example 4: Already async - KEEP AS IS
    func fetchDataModern(from url: URL) async throws -> Data {
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    // Example 5: Multiple completion handler parameters - COMPLEX CASE
    func uploadFile(
        _ data: Data,
        to url: URL,
        progress: @escaping (Double) -> Void,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Simulated upload with progress
        var uploadedBytes = 0
        let totalBytes = data.count
        
        // Progress callback - this pattern is harder to refactor
        DispatchQueue.global().async {
            while uploadedBytes < totalBytes {
                Thread.sleep(forTimeInterval: 0.1)
                uploadedBytes += min(1024, totalBytes - uploadedBytes)
                let progressValue = Double(uploadedBytes) / Double(totalBytes)
                DispatchQueue.main.async {
                    progress(progressValue)
                }
            }
            
            DispatchQueue.main.async {
                completion(.success("Upload completed"))
            }
        }
    }
}

// MARK: - Supporting Types

enum NetworkError: Error {
    case noData
    case invalidResponse
    case serverError(Int)
}

// MARK: - Expected Analysis Results
/*
 CompletionChecker should find:
 1. Line 11: Completion handler - fetchData(from:completion:)
 2. Line 26: withCheckedThrowingContinuation - fetchData(from:) async
 3. Line 34: Completion handler - downloadImage(from:completion:)
 4. Line 44: Already async - fetchDataModern(from:) - NO ACTION NEEDED
 5. Line 51: Multiple completion handlers - uploadFile - COMPLEX
 
 Reporter should recommend:
 1. fetchData(from:completion:) - FULL REFACTOR
    - Remove completion handler version
    - Remove async wrapper
    - Use URLSession.shared.data(from:) directly
    
 2. downloadImage(from:completion:) - FULL REFACTOR
    - Convert to async throws -> UIImage
    - Use modern URLSession API
    
 3. uploadFile - PARTIAL REFACTOR or PRESERVE
    - Progress callback makes this complex
    - Consider AsyncStream for progress reporting
    - Or keep completion-based for now
 */
