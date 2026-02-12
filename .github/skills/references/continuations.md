# Migrating Callback-Based Code to Swift Concurrency with Continuations

**Source:** [Donny Wals - Migrating callback based code to Swift Concurrency with continuations](https://www.donnywals.com/migrating-callback-based-code-to-swift-concurrency-with-continuations/)  
**Published:** April 24, 2022  
**Updated:** October 16, 2024

---

## Overview

Swift's async/await feature significantly enhances the readability of asynchronous code for iOS 13 and later versions. For new projects, it enables us to craft more expressive and easily understandable asynchronous code, which closely resembles synchronous code. However, adopting async/await may require substantial modifications in existing codebases, especially if their asynchronous API relies heavily on completion handler functions.

Fortunately, Swift offers built-in mechanisms that allow us to create a lightweight wrapper around traditional asynchronous code, facilitating its transition into the async/await paradigm. This guide demonstrates how to convert callback-based asynchronous code into functions compatible with async/await, using Swift's `async` keyword.

---

## Converting a Callback-Based Function to Async/Await

### Original Callback-Based Pattern

Callback-based functions vary in structure, but typically resemble the following example:

```swift
func validToken(_ completion: @escaping (Result<Token, Error>) -> Void) {
    // Function body...
}
```

The `validToken(_:)` function above is a simplified example, taking a completion closure and using it at various points to return the outcome of fetching a valid token.

> **Tip:** To understand more about `@escaping` closures, check out [this post on @escaping in Swift](https://www.donnywals.com/what-is-escaping-in-swift/).

### Async/Await Version

To adapt our `validToken` function for async/await, we create an `async throws` version returning a `Token`. The method signature becomes cleaner:

```swift
func validToken() async throws -> Token {
    // ...
}
```

---

## Using Continuations

The challenge lies in integrating the existing callback-based `validToken` with our new async version. We achieve this through a feature known as **continuations**. Swift provides several types of continuations:

- `withCheckedThrowingContinuation`
- `withCheckedContinuation`
- `withUnsafeThrowingContinuation`
- `withUnsafeContinuation`

These continuations exist in **checked** and **unsafe** variants, and in **throwing** and **non-throwing** forms. For an in-depth comparison, refer to [this post that compares checked and unsafe in great detail](https://donnywals.com/the-difference-between-checked-and-unsafe-continuation-in-swift).

### Basic Implementation

Here's the revised `validToken` function using a checked continuation:

```swift
func validToken() async throws -> Token {
    return try await withCheckedThrowingContinuation { continuation in
        validToken { result in
            switch result {
            case .success(let token):
                continuation.resume(returning: token)
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}
```

This function uses `withCheckedThrowingContinuation` to bridge our callback-based `validToken` with the async version. The `continuation` object, created within the function, must be used to resume execution, or the method will remain indefinitely suspended.

### Simplified Implementation with Result

The Swift team has simplified this pattern by introducing a version of `resume` that accepts a `Result` object:

```swift
func validToken() async throws -> Token {
    return try await withCheckedThrowingContinuation { continuation in
        validToken { result in
            continuation.resume(with: result)
        }
    }
}
```

This approach is more streamlined and elegant.

---

## Critical Rules for Continuations

Remember two crucial points when working with continuations:

1. **A continuation can only be resumed once.** Calling `resume` multiple times will cause a runtime error.
2. **It's your responsibility to call `resume` within the continuation closure.** Failure to do so will leave the function awaiting indefinitely.

Despite minor differences (like error handling), all four `with*Continuation` functions follow these same fundamental rules.

---

## Choosing the Right Continuation Type

### Checked vs Unsafe

- **Checked continuations** (`withCheckedContinuation`, `withCheckedThrowingContinuation`):
  - Perform runtime checks to ensure you resume exactly once
  - Provide helpful diagnostics if you violate the rules
  - Recommended for development and production code

- **Unsafe continuations** (`withUnsafeContinuation`, `withUnsafeThrowingContinuation`):
  - No runtime checks; better performance
  - Use only when you're absolutely certain the code is correct
  - Violating the rules causes undefined behavior

### Throwing vs Non-Throwing

- **Throwing continuations** (`withCheckedThrowingContinuation`, `withUnsafeThrowingContinuation`):
  - Use when the async function can throw errors
  - Can call `resume(throwing:)` or `resume(with: Result<T, Error>)`

- **Non-throwing continuations** (`withCheckedContinuation`, `withUnsafeContinuation`):
  - Use when the async function cannot throw
  - Can only call `resume(returning:)` or `resume(with: Result<T, Never>)`

---

## Practical Application

Continuations are an excellent tool for gradually integrating async/await into your existing codebase without a complete overhaul. You can use them to transition large code segments into async/await gradually, allowing for intermediate layers that support async/await in, say, view models and networking, without needing a full rewrite upfront.

### Example Use Cases

1. **Wrapping legacy networking code** that uses completion handlers
2. **Bridging third-party libraries** that haven't adopted async/await yet
3. **Incremental migration** of large codebases to Swift Concurrency
4. **Protocol conformance** where you need to provide async versions alongside completion-based ones

---

## Summary

Continuations offer a straightforward and elegant solution for converting existing callback-based functions into async/await compatible ones. By understanding the different types of continuations and following the critical rules, you can safely modernize your codebase incrementally.

**Key Takeaways:**
- Use `withCheckedThrowingContinuation` for most migration scenarios
- Always resume the continuation exactly once
- Prefer `resume(with: result)` when working with `Result` types
- Start with checked continuations and only move to unsafe variants when performance profiling demands it
- Continuations enable incremental adoption of Swift Concurrency

---

## Related Resources

- [The difference between checked and unsafe continuations in Swift](https://www.donnywals.com/the-difference-between-checked-and-unsafe-continuation-in-swift/)
- [What is @escaping in Swift?](https://www.donnywals.com/what-is-escaping-in-swift/)
- [How to unwrap [weak self] in Swift Concurrency Tasks?](https://www.donnywals.com/how-to-use-weak-self-in-swift-concurrency-tasks/)
