# Testing AI Agents

This directory contains test files and instructions for testing the async/await refactoring agents.

## Agent Architecture

```
CompletionChecker (Entry Point)
    ↓
    Receives: List of changed files from pipeline
    ↓
    Scans files for completion handlers and continuations
    ↓
    Invokes: Reporter Agent
        ↓
        Invokes: Analyzer Agent (for each file)
            ↓
            Analyzer recursively analyzes dependencies (DFS)
            ↓
            Returns: Factual analysis data
        ↓
        Makes decisions and creates recommendations
        ↓
        Returns: Prioritized refactoring recommendations
```

## Agents

1. **CompletionChecker** (`.github/agents/completionchecker.agent.md`)
   - Entry point for the workflow
   - Scans provided files for async patterns
   - Calls Reporter agent with findings

2. **Reporter** (`.github/agents/reporter.agent.md`)
   - Orchestrator and decision-maker
   - Calls Analyzer agent for each file
   - Makes refactoring decisions (Full/Partial/None)
   - Generates prioritized recommendations

3. **Analyzer** (`.github/agents/analysis.agent.md`)
   - Data collector (read-only)
   - Performs DFS through method dependencies
   - Recursively calls itself as subagent
   - Reports facts without recommendations

## Test Files

The `test-files/` directory contains sample Swift files with various async patterns:

- `NetworkService.swift` - Completion handlers with Result type
- `DataService.swift` - Mix of checked and unsafe continuations
- `APIClient.swift` - @objc methods with completion handlers
- `LegacyService.swift` - Old-style completion handlers

## How to Test

### Manual Testing with GitHub Copilot Chat

1. Open VS Code with GitHub Copilot Chat
2. Reference the CompletionChecker agent:
   ```
   @workspace Using the CompletionChecker agent at .github/agents/completionchecker.agent.md, 
   analyze the following files:
   - test-files/NetworkService.swift
   - test-files/DataService.swift
   ```

3. The agent will:
   - Scan the files for patterns
   - Call the Reporter agent
   - Reporter will call Analyzer for each file
   - Return comprehensive refactoring recommendations

### Expected Flow

1. **CompletionChecker** finds patterns:
   ```
   Found 5 completion handlers in NetworkService.swift
   Found 3 continuations in DataService.swift
   ```

2. **Reporter** invokes **Analyzer** for each file:
   ```
   Analyzing NetworkService.swift...
   - fetchData method uses withCheckedThrowingContinuation
   - No @objc exposure
   - Dependencies: URLSession (async-compatible)
   ```

3. **Reporter** makes decisions:
   ```
   Decision: ⭐ Full Refactor
   Rationale: No Objective-C constraints, all dependencies support async/await
   Recommendation: Remove continuation wrapper, use URLSession.data(for:) directly
   ```

### Test Scenarios

#### Scenario 1: Simple Continuation Removal
- **File**: `test-files/NetworkService.swift`
- **Expected**: Full refactor - remove continuation wrapper
- **Reason**: URLSession already supports async/await

#### Scenario 2: Objective-C Interop
- **File**: `test-files/APIClient.swift`
- **Expected**: Partial refactor - keep @objc method with completion, add async variant
- **Reason**: @objc exposure requires completion handler

#### Scenario 3: Complex Dependencies
- **File**: `test-files/DataService.swift`
- **Expected**: Mixed recommendations based on dependency analysis
- **Reason**: Some methods can be fully refactored, others have constraints

## CI/CD Integration Example

```yaml
# .github/workflows/async-refactor-check.yml
name: Async/Await Refactoring Analysis

on:
  pull_request:
    paths:
      - '**/*.swift'

jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Get changed Swift files
        id: changed-files
        uses: tj-actions/changed-files@v40
        with:
          files: |
            **/*.swift
      
      - name: Analyze with CompletionChecker
        run: |
          echo "Changed files:"
          echo "${{ steps.changed-files.outputs.all_changed_files }}"
          # Pass file list to GitHub Copilot Workspace agent
          # Or use GitHub Copilot CLI if available
```

## Reference Materials

The agents have access to comprehensive Swift Concurrency guides in `.github/skills/references/`:

- `continuations.md` - Migrating callback-based code
- `async-await-basics.md` - Basic async/await patterns
- `migration.md` - Swift 6 migration strategies
- `testing.md` - Async testing patterns
- And more...

## Validation

After receiving recommendations:

1. **Review the priority ranking** - Start with high-priority, low-risk items
2. **Check Objective-C constraints** - Verify @objc analysis is correct
3. **Validate dependency analysis** - Confirm DFS found all dependencies
4. **Test the changes** - Follow the testing strategy in recommendations
5. **Iterate** - Re-run analysis after making changes to track progress
