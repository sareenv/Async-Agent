# Quick Setup Guide

Get the Async/Await Refactoring Agent running in your CI/CD in 5 minutes!

## ⚡ Quick Setup (5 minutes)

### Step 1: Create GitHub Token (2 min)
```bash
# Go to: https://github.com/settings/tokens?type=beta
# 1. Click "Generate new token"
# 2. Name: "Copilot CLI CI/CD"
# 3. Expiration: 90 days
# 4. Permissions: Copilot → Read
# 5. Generate and copy token
```

### Step 2: Add to Repository (1 min)
```bash
# Go to: Your Repo → Settings → Secrets → Actions
# 1. Click "New repository secret"
# 2. Name: COPILOT_GITHUB_TOKEN
# 3. Value: [paste token]
# 4. Click "Add secret"
```

### Step 3: Commit Workflow (1 min)
```bash
git add .github/workflows/async-refactoring-analysis.yml
git add .github/agents/
git commit -m "Add async/await refactoring analysis workflow"
git push origin main
```

### Step 4: Test It! (1 min)
```bash
# Create a test branch
git checkout -b test-async-agent

# Add a test file with completion handler
cat > TestService.swift << 'EOF'
import Foundation

class TestService {
    func fetchData(completion: @escaping (String) -> Void) {
        DispatchQueue.main.async {
            completion("Hello")
        }
    }
}
EOF

# Commit and push
git add TestService.swift
git commit -m "Test: Add completion handler"
git push origin test-async-agent

# Create PR and watch the magic! 🎉
```

## ✅ What to Expect

When you create the PR:

1. ✅ **Workflow starts** automatically
2. 📝 **Detects** `TestService.swift` changed
3. 🤖 **Analyzes** completion handler pattern
4. 📊 **Generates** recommendation report
5. 💬 **Comments** on PR with findings
6. 🎯 **Suggests** converting to async/await

**Example PR Comment:**
```markdown
## 🔍 Async/Await Refactoring Analysis

✅ Analysis complete

<details>
<summary>📋 View Full Analysis Report</summary>

### Method: fetchData(completion:)
**Decision**: ⭐ Full Refactor
**Rationale**: Simple completion handler can be converted to async

**Recommendation**:
```swift
func fetchData() async -> String {
    return "Hello"
}
```

**Priority**: 🔴 High
</details>
```

## 🎯 Common Use Cases

### Use Case 1: Check PRs Only (Recommended)

**Current setup** - Workflow runs on:
- ✅ Pull requests to develop/main
- ✅ Pushes to develop/main
- ✅ Only when `.swift` files change

**To run only on PRs:**
Edit `.github/workflows/async-refactoring-analysis.yml`:
```yaml
on:
  pull_request:  # Remove push: section
    branches:
      - develop
      - main
```

### Use Case 2: Block Merges on High Priority

**Current setup** - Informational only (won't block merge)

**To block merges:**
Edit `.github/workflows/async-refactoring-analysis.yml`, line ~228:
```yaml
# Change from:
# exit 1

# To:
exit 1
```

### Use Case 3: Different Base Branch

**To compare against `main` instead of `develop`:**
Edit `.github/workflows/async-refactoring-analysis.yml`, line ~40:
```yaml
# Change:
git fetch origin develop
COMPARE_REF="origin/develop"

# To:
git fetch origin main
COMPARE_REF="origin/main"
```

## 🔧 Troubleshooting

### "Workflow didn't run"
```bash
# Check:
✓ Workflow file exists in .github/workflows/
✓ Swift files were modified
✓ Changes pushed to correct branch
✓ Workflow enabled in repo settings
```

### "No analysis report found"
```bash
# Check:
✓ COPILOT_GITHUB_TOKEN secret exists
✓ Token has Copilot permissions
✓ Token hasn't expired
✓ Agent files exist in .github/agents/
```

### "Permission denied"
```bash
# Check:
✓ PAT has "Copilot Requests: Read" scope
✓ PAT has access to this repository
✓ Organization allows Copilot usage
```

## 📚 Next Steps

### Customize Agents
```bash
# Edit agent behavior:
vim .github/agents/completionchecker.agent.md
vim .github/agents/reporter.agent.md
vim .github/agents/analysis.agent.md

# Test with local files:
./test-agents.sh
```

### View Full Documentation
- **Complete setup**: `.github/workflows/CI-CD-SETUP.md`
- **Architecture**: `README.md`
- **Testing guide**: `test-files/TESTING.md`
- **Reference materials**: `.github/skills/references/`

## 🎉 Success Checklist

- [ ] GitHub PAT created with Copilot permissions
- [ ] Secret `COPILOT_GITHUB_TOKEN` added to repository
- [ ] Workflow file committed to repository
- [ ] Test PR created with completion handler
- [ ] Workflow ran successfully
- [ ] PR comment appeared with analysis
- [ ] Report downloaded from artifacts
- [ ] Team understands how to interpret results

## 💡 Tips

1. **Start informational** - Don't block merges initially
2. **Review first 5 PRs** manually to build confidence
3. **Customize thresholds** based on your codebase
4. **Document exceptions** in code comments
5. **Update agents** as you learn patterns

## 🆘 Need Help?

1. Check workflow logs in Actions tab
2. Review [CI-CD-SETUP.md](.github/workflows/CI-CD-SETUP.md)
3. Test locally with `./test-agents.sh`
4. Check agent definitions in `.github/agents/`

---

**Time invested**: 5 minutes  
**Value gained**: Automated async/await analysis on every PR  
**ROI**: ∞ 🚀
