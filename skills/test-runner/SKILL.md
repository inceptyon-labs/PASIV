---
name: test-runner
description: Test runner helper. Runs test suite and reports results. Used by /kick for initial baseline and verification gate.
model: haiku
context: fork
allowed-tools:
  - Bash
  - Read
---

# Test Runner

Runs the test suite for the project and reports results.

---

## Usage

Called with no arguments - automatically detects test framework and runs tests.

---

## Test Detection & Execution

Detect project type and run appropriate test command:

```bash
# Detect and run tests
if [ -f "package.json" ]; then
  if grep -q '"test"' package.json; then
    npm test
  elif command -v bun &> /dev/null; then
    bun test
  fi
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest
elif [ -f "go.mod" ]; then
  go test ./...
elif [ -f "Cargo.toml" ]; then
  cargo test
elif [ -f "build.gradle" ] || [ -f "pom.xml" ]; then
  ./gradlew test || mvn test
else
  echo "❌ No test framework detected"
  exit 1
fi
```

Store exit code: `EXIT_CODE=$?`

---

## Output Parsing

Parse test output to extract:
- **Total tests**: How many tests ran
- **Passed**: How many passed
- **Failed**: How many failed
- **Skipped**: How many skipped
- **Exit code**: 0 = success, non-zero = failure

Common patterns:
```
# Jest/Vitest
"Tests:       2 failed, 45 passed, 47 total"

# Pytest
"45 passed, 2 failed in 1.23s"

# Go
"FAIL	package/name	0.123s"
"ok  	package/name	0.123s"

# Cargo
"test result: FAILED. 45 passed; 2 failed; 0 ignored"
```

---

## Report Format

### Success

```
✓ All tests passed

Tests:     47/47 passed
Skipped:   0
Exit code: 0
```

### Failure

```
✗ Tests failed

Tests:     45/47 passed, 2 failed
Skipped:   0
Exit code: 1

Failed tests:
- test/auth.test.ts:42 - should reject invalid tokens
- test/user.test.ts:15 - should validate email format

[Include relevant error messages from output]
```

### No Tests Found

```
⚠ No tests found

The test command ran but no tests were detected. This might indicate:
- Tests haven't been written yet
- Test files are in unexpected locations
- Test framework not configured

Exit code: 0
```

---

## Error Handling

If test command fails to run (not test failures, but command not found):

```
❌ Failed to run tests

Error: [command error message]

This likely means:
- Dependencies not installed (run npm install, pip install, etc.)
- Test framework not configured
- Invalid test configuration
```

---

## Output

Return structured report with:
1. Status icon (✓/✗/⚠)
2. Summary line
3. Test counts
4. Exit code
5. Failed test details (if any)
6. Error context (if needed)
