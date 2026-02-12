# CI/CD Integration Guide

This guide explains how to integrate the Async/Await Refactoring Agents into your GitHub Actions workflow.

## Prerequisites

### 1. GitHub Copilot CLI Access

You need a GitHub account with Copilot access. Create a fine-grained Personal Access Token (PAT) with the following permissions:

**Required Scopes:**
- `Copilot Requests: Read`

**Steps to create PAT:**
1. Go to GitHub Settings → Developer settings → Personal access tokens → Fine-grained tokens
2. Click "Generate new token"
3. Give it a descriptive name: "Copilot CLI CI/CD Token"
4. Set expiration (recommended: 90 days with auto-renewal reminder)
5. Under "Account permissions" → Select `Copilot` → Set to `Read`
6. Generate token and copy it

### 2. Add Token to Repository Secrets

1. Go to your repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `COPILOT_GITHUB_TOKEN`
4. Value: Paste your PAT
5. Click "Add secret"

## Workflow Setup

The workflow is already created at `.github/workflows/async-refactoring-analysis.yml`

### What It Does

1. **Detects Changed Swift Files**
   - Compares current branch with `develop` (or PR base branch)
   - Identifies all modified `.swift` files
   - Saves list to `changed_files.txt`

2. **Installs GitHub Copilot CLI**
   - Sets up Node.js 20
   - Installs `@githubnext/github-copilot-cli`

3. **Runs CompletionChecker Agent**
   - Reads the agent definition from `.github/agents/completionchecker.agent.md`
   - Passes the list of changed files
   - Agent scans for completion handlers and continuations
   - Invokes Reporter agent for analysis
   - Reporter invokes Analyzer for dependency analysis
   - Generates comprehensive report

4. **Uploads Report**
   - Saves report as workflow artifact
   - Retains for 30 days

5. **Comments on PR**
   - Posts analysis summary to PR
   - Includes full report in collapsible section
   - Highlights high-priority items

6. **Optional: Blocks Merge**
   - Can be configured to fail workflow on high-priority items
   - Currently set to informational mode only

## Workflow Triggers

The workflow runs on:

```yaml
on:
  pull_request:
    branches:
      - develop
      - main
    paths:
      - '**/*.swift'
  push:
    branches:
      - develop
      - main
    paths:
      - '**/*.swift'
```

**Only runs when Swift files change!**

## Configuration Options

### Enforce Blocking on High Priority Items

By default, the workflow is **informational only**. To make it block merges:

Edit `.github/workflows/async-refactoring-analysis.yml`, line 228:

```yaml
# Current (informational):
# exit 1

# Change to (blocking):
exit 1
```

### Customize Priority Threshold

To change what constitutes "high priority", edit the CompletionChecker agent's kill switch logic in `.github/agents/completionchecker.agent.md`.

### Change Base Branch

To compare against a different branch, modify the workflow:

```yaml
- name: Get changed Swift files
  run: |
    # Change this line:
    git fetch origin develop
    COMPARE_REF="origin/develop"
    
    # To your preferred branch:
    git fetch origin main
    COMPARE_REF="origin/main"
```

## Understanding the Output

### Workflow Run

When the workflow runs, you'll see:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Running Async/Await Refactoring Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Changed Swift files:
Sources/NetworkService.swift
Sources/DataService.swift

Invoking GitHub Copilot Agent...
✅ Analysis complete
```

### Report Structure

The generated report (`async-refactoring-reports/analysis-report.md`) contains:

1. **Pattern Detection Results**
   - Table of all completion handlers and continuations found
   - File locations, line numbers, patterns

2. **Analyzer Results**
   - Dependency analysis for each file
   - DFS through method call trees
   - Objective-C constraints identified
   - Technical limitations documented

3. **Reporter Recommendations**
   - Decision for each method (Full/Partial/Preserve)
   - Rationale with evidence
   - Step-by-step implementation guidance
   - Priority ranking (🔴 High / 🟡 Medium / 🟢 Low)
   - Estimated effort and risk level

4. **Summary**
   - Implementation order
   - Overall strategy
   - Success metrics

### PR Comment

The bot posts a comment like:

```markdown
## 🔍 Async/Await Refactoring Analysis

✅ No high priority refactoring required.

<details>
<summary>📋 View Full Analysis Report</summary>

[Full report content here]

</details>

---
📦 [Download full report](https://github.com/...)
```

Or if high priority items exist:

```markdown
## 🔍 Async/Await Refactoring Analysis

🔴 **High Priority Refactoring Opportunities Found**

This PR introduces code with completion handlers or continuations that should be refactored to async/await.

<details>
<summary>📋 View Full Analysis Report</summary>

[Full report with recommendations]

</details>
```

## Troubleshooting

### Workflow Doesn't Run

**Check:**
- Swift files were actually modified
- Workflow file is in `.github/workflows/` directory
- Workflow is committed to the branch
- Triggers match your event (push/PR to correct branch)

### "No analysis report found"

**Solutions:**
- Verify `COPILOT_GITHUB_TOKEN` secret is set correctly
- Check that PAT has correct permissions
- Review workflow logs for Copilot CLI errors
- Ensure agent files exist in `.github/agents/`

### Copilot CLI Authentication Failed

**Solutions:**
- Regenerate PAT with correct scopes
- Update repository secret
- Verify token hasn't expired
- Check token has access to this repository

### Report Generated but Empty

**Possible causes:**
- Agent didn't find any patterns (good!)
- Files weren't properly read
- Agent invocation failed silently

**Debug:**
- Check workflow artifact
- Review "Run CompletionChecker Agent" step logs
- Manually test agent with test files

### False Positives

If the agent flags code that's intentionally using completion handlers:

1. **Document in code comments** why the pattern is necessary
2. **Request senior review** to validate the decision
3. **Update agent logic** if pattern should be excluded
4. **Override the check** (last resort)

## Advanced Usage

### Custom Agent Behavior

Edit `.github/agents/completionchecker.agent.md` to customize:
- Pattern detection rules
- Priority thresholds
- Kill switch logic
- Output format

### Multiple Agents

You can create multiple workflows for different checks:

- `async-refactoring-analysis.yml` - Async patterns (this one)
- `security-check.yml` - Security vulnerabilities
- `documentation-check.yml` - Documentation coverage

Each uses the same Copilot CLI pattern with different agents.

### Integration with Other Tools

Combine with existing CI/CD:

```yaml
jobs:
  # Existing jobs
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run tests
        run: swift test
  
  # Add agent analysis
  async-analysis:
    runs-on: ubuntu-latest
    needs: test  # Run after tests pass
    steps:
      # ... agent analysis steps
```

## Cost Considerations

- **Workflow executes**: Only when Swift files change
- **Copilot API calls**: Proportional to number of files analyzed
- **Artifact storage**: Reports stored for 30 days

**Optimization tips:**
- Use path filters to narrow scope
- Adjust retention period as needed
- Run on PR only, not every push

## Example Scenarios

### Scenario 1: Clean PR

```
Developer creates PR with new async method
→ Workflow runs
→ No patterns detected
→ ✅ Green check
→ PR can be merged
```

### Scenario 2: Completion Handler Added

```
Developer adds method with @escaping completion
→ Workflow runs
→ Pattern detected
→ Reporter analyzes
→ Recommends: "Convert to async throws"
→ 🔴 High priority
→ PR comment posted
→ Developer reviews and refactors
→ Push update
→ Workflow re-runs
→ ✅ Clean
→ Merge
```

### Scenario 3: Objective-C Constraint

```
Developer adds @objc method with completion
→ Workflow runs
→ Pattern detected
→ Analyzer finds @objc attribute
→ Reporter decides: Preserve as-is
→ 🟢 Low priority (documented constraint)
→ ✅ Green check
→ Merge
```

## Best Practices

1. **Start Informational**
   - Run workflow non-blocking initially
   - Build confidence in recommendations
   - Enable blocking after team agrees on standards

2. **Review Regularly**
   - Check artifact reports even when green
   - Learn from recommendations
   - Update agent logic based on feedback

3. **Document Exceptions**
   - Use code comments for intentional patterns
   - Update agent to recognize valid exceptions
   - Maintain list of approved exceptions

4. **Iterate on Prompts**
   - Agent definitions are markdown
   - Easy to update
   - Test changes with test files first

5. **Monitor Costs**
   - Track Copilot API usage
   - Optimize file filters if needed
   - Balance thoroughness with efficiency

## Support

- **Agent Issues**: Review agent markdown files in `.github/agents/`
- **Workflow Issues**: Check `.github/workflows/async-refactoring-analysis.yml`
- **Copilot CLI**: [GitHub Copilot CLI Documentation](https://github.com/github/copilot-cli)
- **Test Locally**: Use `test-files/` directory to validate changes

## Next Steps

1. ✅ Set up `COPILOT_GITHUB_TOKEN` secret
2. ✅ Commit workflow to repository
3. ✅ Create a test PR with a completion handler
4. ✅ Verify workflow runs and generates report
5. ✅ Review and adjust configuration
6. ✅ Enable blocking (optional)
7. ✅ Roll out to team
