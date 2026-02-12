# How to Test the Agents

This guide provides step-by-step instructions for testing the async/await refactoring agents.

## Quick Start

### Step 1: Invoke CompletionChecker

In GitHub Copilot Chat, use:

```
@workspace Using the CompletionChecker agent defined at .github/agents/completionchecker.agent.md, 
analyze these files for completion handler and continuation patterns:

- test-files/NetworkService.swift
- test-files/DataService.swift
- test-files/APIClient.swift
- test-files/LegacyService.swift

Please provide a comprehensive analysis with refactoring recommendations.
```

### Step 2: Review the Output

The CompletionChecker should:

1. **Scan the files** and create a table of findings
2. **Invoke the Reporter agent** with the findings
3. **Reporter invokes Analyzer** for each file to perform DFS
4. **Reporter provides recommendations** with priorities

### Expected Results

You should see output similar to:

```markdown
## Pattern Detection Results

| # | File | Line | Pattern | Method Signature |
|---|------|------|---------|------------------|
| 1 | test-files/NetworkService.swift | 11 | Completion handler | fetchData(from:completion:) |
| 2 | test-files/NetworkService.swift | 26 | withCheckedThrowingContinuation | fetchData(from:) async |
| 3 | test-files/DataService.swift | 27 | withUnsafeContinuation | loadDataUnsafe(id:) |
...

## Refactoring Recommendations

### File: test-files/NetworkService.swift

#### Method: fetchData(from:completion:)
**Decision**: ⭐ Full Refactor
**Rationale**: URLSession already provides async API, continuation wrapper is unnecessary
**Recommendation**: Remove both completion and async wrapper versions, use URLSession.shared.data(from:) directly
...
```

## Testing Individual Agents

### Test the Analyzer Directly

```
@workspace Using the Analyzer agent at .github/agents/analysis.agent.md,
perform a deep dependency analysis on the method fetchData in test-files/NetworkService.swift.
Track all method calls and identify any completion handler or continuation patterns.
```

Expected: Factual report about the method, its dependencies, and technical constraints (NO recommendations)

### Test the Reporter Directly

```
@workspace Using the Reporter agent at .github/agents/reporter.agent.md,
analyze test-files/APIClient.swift and provide refactoring recommendations considering 
Objective-C interoperability constraints.
```

Expected: Reporter should invoke Analyzer, then provide categorized recommendations with priorities

## Test Scenarios

### Scenario 1: Simple Refactor (NetworkService.swift)

**Test**: Lines 26-31 use withCheckedThrowingContinuation to wrap a method that just calls URLSession

**Expected Decision**: ⭐ Full Refactor

**Expected Recommendation**:
- Remove the continuation wrapper
- Remove the completion handler version
- Use `URLSession.shared.data(from:)` directly
- Update all call sites

**Why**: URLSession already has async/await support, wrapping it in a continuation adds unnecessary complexity

---

### Scenario 2: Objective-C Constraint (APIClient.swift)

**Test**: Line 11-21, @objc method with completion handler

**Expected Decision**: 🔒 Preserve As-Is (for @objc method) + Keep async variant

**Expected Recommendation**:
- Keep @objc method with completion handler (required for Objective-C)
- Keep or add async variant for Swift callers
- Document that both versions must be maintained
- Internal implementation can be modernized

**Why**: Objective-C doesn't support async/await, completion handler is mandatory

---

### Scenario 3: Unsafe to Checked (DataService.swift)

**Test**: Line 27, withUnsafeContinuation without performance justification

**Expected Decision**: 🔶 Partial Refactor

**Expected Recommendation**:
- Change `withUnsafeContinuation` to `withCheckedContinuation`
- Keep continuation pattern (may be wrapping third-party API)
- Add comment explaining why continuation is needed
- Consider if continuation is actually necessary

**Why**: Unsafe variants should only be used with strong performance justification

---

### Scenario 4: Callback Hell (LegacyService.swift)

**Test**: Line 72-95, deeply nested callbacks

**Expected Decision**: ⭐ Full Refactor (High Priority)

**Expected Recommendation**:
- Convert to async/await
- Flatten nested structure
- Simplify error handling
- Provide before/after code example

**Expected Impact**:
- Massive readability improvement
- Better error handling
- Easier to maintain
- Reduced complexity

---

### Scenario 5: Delegate Pattern (LegacyService.swift)

**Test**: Line 42-59, completion handler mixed with delegate

**Expected Decision**: 🔶 Partial Refactor

**Expected Recommendation**:
- Convert completion handler to async/await
- Keep delegate pattern (not completion-based)
- Consider AsyncSequence for delegate events (optional)
- Modernize internal implementation

**Why**: Delegates serve a different purpose than completion handlers

## Validation Checklist

After running the analysis, verify:

- [ ] CompletionChecker found all pattern instances
- [ ] Reporter invoked Analyzer for each file
- [ ] Analyzer performed DFS and reported dependencies
- [ ] Objective-C constraints were correctly identified
- [ ] Recommendations are categorized (Full/Partial/None)
- [ ] Priority ranking makes sense
- [ ] Code examples are provided in recommendations
- [ ] Testing strategy is mentioned
- [ ] Reference materials are cited when relevant

## Common Issues

### Issue: Agent doesn't invoke subagents

**Solution**: Make sure the agent descriptor includes:
```yaml
tools: ['agent']  # Required for calling subagents
```

### Issue: Incomplete analysis

**Solution**: Check that Analyzer is using itself recursively for DFS:
- Should see nested analysis of dependencies
- Should track visited methods to avoid cycles

### Issue: Wrong recommendations

**Solution**: Verify Reporter is using analysis data:
- Should reference specific findings from Analyzer
- Should apply decision framework consistently
- Should cite references from `.github/skills/references/`

## Advanced Testing

### Test Recursive Analysis

Create a file with deep dependency chains:

```swift
// A calls B calls C calls D
func methodA(completion: @escaping (String) -> Void) {
    methodB { result in
        completion("A: " + result)
    }
}

func methodB(completion: @escaping (String) -> Void) {
    methodC { result in
        completion("B: " + result)
    }
}
// ... etc
```

**Expected**: Analyzer should recursively analyze the entire chain using DFS

### Test Circular Dependencies

```swift
class ServiceA {
    let serviceB: ServiceB
    func doWork(completion: @escaping (String) -> Void) {
        serviceB.help { completion("A: \($0)") }
    }
}

class ServiceB {
    let serviceA: ServiceA
    func help(completion: @escaping (String) -> Void) {
        serviceA.doWork { completion("B: \($0)") }
    }
}
```

**Expected**: Analyzer should detect cycle and avoid infinite recursion

## Success Criteria

The test is successful if:

1. ✅ All completion handlers and continuations are found
2. ✅ Objective-C constraints are correctly identified
3. ✅ Dependencies are fully analyzed (DFS works)
4. ✅ Recommendations are actionable and correct
5. ✅ Priority ranking makes sense
6. ✅ Code examples are accurate
7. ✅ Reference materials are cited appropriately
