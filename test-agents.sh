#!/bin/bash
# test-agents.sh - Helper script to test the async/await refactoring agents

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  iOS Async/Await Refactoring Agent System - Test Runner       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Test Files Available:${NC}"
echo "  1. test-files/NetworkService.swift - Basic completion handlers"
echo "  2. test-files/DataService.swift - Checked vs unsafe continuations"
echo "  3. test-files/APIClient.swift - Objective-C interop constraints"
echo "  4. test-files/LegacyService.swift - Old-style patterns, callback hell"
echo ""

echo -e "${BLUE}Agent Structure:${NC}"
echo "  CompletionChecker → Reporter → Analyzer"
echo "                         ↓"
echo "                    (Analyzer calls itself recursively)"
echo ""

echo -e "${YELLOW}To test the agents, use GitHub Copilot Chat:${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Option 1: Test CompletionChecker (Full Workflow)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'EOF'
@workspace Using the CompletionChecker agent at .github/agents/completionchecker.agent.md, 
analyze these test files for completion handler and continuation patterns:

- test-files/NetworkService.swift
- test-files/DataService.swift
- test-files/APIClient.swift
- test-files/LegacyService.swift

Please provide comprehensive refactoring recommendations.
EOF
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Option 2: Test Reporter Directly"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'EOF'
@workspace Using the Reporter agent at .github/agents/reporter.agent.md,
analyze test-files/APIClient.swift and provide refactoring recommendations.
Pay special attention to Objective-C interoperability constraints.
EOF
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Option 3: Test Analyzer Directly"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'EOF'
@workspace Using the Analyzer agent at .github/agents/analysis.agent.md,
perform a deep dependency analysis on test-files/LegacyService.swift.
Analyze the complexOperation method and all its dependencies using DFS.
EOF
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Option 4: Test Specific Scenario"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
cat << 'EOF'
@workspace Test the callback hell refactoring scenario:

Using the CompletionChecker agent, analyze the complexOperation method 
in test-files/LegacyService.swift (starting at line 72). This method has 
deeply nested callbacks that should be a high-priority refactor candidate.

Expected: Full Refactor recommendation with before/after code example.
EOF
echo ""

echo -e "${GREEN}Documentation:${NC}"
echo "  • Full testing guide: test-files/TESTING.md"
echo "  • Agent overview: README.md"
echo "  • Test file details: test-files/README.md"
echo "  • CI/CD setup: .github/workflows/CI-CD-SETUP.md"
echo ""

echo -e "${BLUE}CI/CD Integration:${NC}"
echo "  • GitHub Actions workflow: .github/workflows/async-refactoring-analysis.yml"
echo "  • Automatically runs on PRs with Swift changes"
echo "  • Generates changed_files.txt from develop branch comparison"
echo "  • Uses GitHub Copilot CLI to invoke agents"
echo "  • Posts analysis to PR comments"
echo ""

echo -e "${BLUE}Agent Definitions:${NC}"
echo "  • CompletionChecker: .github/agents/completionchecker.agent.md"
echo "  • Reporter: .github/agents/reporter.agent.md"
echo "  • Analyzer: .github/agents/analysis.agent.md"
echo ""

echo -e "${GREEN}Reference Materials:${NC}"
ls -1 .github/skills/references/*.md 2>/dev/null | sed 's/^/  • /' || echo "  • See .github/skills/references/"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Copy one of the prompts above and paste into GitHub Copilot Chat"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
