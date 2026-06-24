---
name: agent-commit-workflow
description: (no description)
disable-model-invocation: true
---

# Agent Commit Workflow

## Table of Contents
- [Principles](#principles)
- [Commit Structure](#commit-structure)
- [Workflow Steps](#workflow-steps)
- [Commit Messages](#commit-messages)
- [Working with Jujutsu](#working-with-jujutsu)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Principles

The agent commit workflow is based on these core principles:

1. **Atomic Changes**: Each commit represents exactly one logical change
2. **Clear Communication**: Commit messages clearly explain what was changed and why
3. **Progressive Implementation**: Build complex features through a series of smaller, focused commits
4. **Verifiable Steps**: Each commit should result in a verifiable, working state
5. **Traceable History**: Changes should be easy to understand and trace through history
6. **Tool Consistency**: Always use agent functions when available instead of raw VCS commands

## Commit Structure

### What Makes a Good Commit?

A good commit:
- Implements exactly one logical change
- Includes all related changes across files needed for that change
- Leaves the codebase in a working state
- Has a clear, descriptive commit message
- Is independently reviewable

### Granularity Guidelines

| Type of Change | Appropriate Granularity | Example |
|----------------|-------------------------|---------|
| New Feature | One commit per logical component | "Add user authentication form" |
| Bug Fix | One commit per fixed issue | "Fix email validation regex" |
| Refactoring | One commit per refactored component | "Refactor error handling in auth service" |
| Documentation | One commit per document or related set | "Update API authentication docs" |
| Testing | One commit per test suite/area | "Add tests for user registration flow" |

## Workflow Steps

1. **Plan Before Coding**
   - Understand the requirement
   - Break down into logical changes
   - Determine implementation order

2. **Implement One Change**
   - Focus on one logical change
   - Ensure all related parts are included
   - Verify it works before committing

3. **Commit**
   - Write a clear commit message
   - Reference any relevant issues/tasks
   - Use appropriate prefixes/tags

4. **Verify**
   - Confirm the change works as expected
   - Run tests if available
   - Check code quality

5. **Repeat**
   - Move to the next logical change
   - Maintain focus on one change at a time

## Commit Messages

### Format

```
[Type]: Brief description of the change

More detailed explanation if needed, including:
- Why this change was made
- What it accomplishes
- Any special considerations
```

### Types

- `[FEAT]` - New features
- `[FIX]` - Bug fixes
- `[REFACTOR]` - Code changes that neither fix bugs nor add features
- `[DOCS]` - Documentation only changes
- `[TEST]` - Adding or modifying tests
- `[CHORE]` - Changes to the build process, tools, etc.

### Examples

```
[FEAT]: Add user registration form

Implements the registration form with:
- Email and password fields with validation
- Terms of service agreement checkbox
- Client-side validation with error messages
```

```
[FIX]: Correct email validation regex

Fixed the regex pattern to properly validate email addresses with 
subdomains and special characters. Previous pattern was rejecting
valid emails containing plus signs.
```

## Working with Jujutsu

When using Jujutsu (jj) for version control:

### Mandatory Tool Usage Requirements

**Always use jj-agent functions when available:**
- **Rationale**: Agent functions provide consistency, tracking, and protection against interface changes
- **Validation**: Using your own tools validates their effectiveness in real-world scenarios
- **Benefits**: Enforces good patterns, enables metrics, creates usage examples

**Examples of required function usage:**
```bash
# CORRECT: Use agent functions (automatically available)
jj-agent-branch feature-name
jj-agent-commit "[FEAT] description"
jj-agent-wip "working on feature"
jj-agent-session-start session-name

# INCORRECT: Don't bypass agent functions
jj bookmark create feature-name
jj commit -m "Agent: [FEAT] description"
jj wip
```

**Exception**: Only use raw jj commands when no agent function exists for that operation.

### Creating Commits

**Standard agent commits:**
```bash
# Create a commit with proper message
jj-agent-commit "[FEAT] Added login form"

# Commit specific files
jj-agent-commit-files "[FEAT] Added form validation" src/validation.js src/forms/login.js

# Create an interactive commit (selecting changes to include)
jj-agent-commit-interactive "[FEAT] Added input validation"

# For work-in-progress
jj-agent-wip "working on auth flow"
```

**Note**: Functions are automatically available after shell profile setup. See `docs/jj-agent-setup.md` for one-time configuration.

### Managing Implementation Flow

```bash
# Create bookmark for a new feature
jj-agent-branch feature-user-auth

# View history of Agent commits
jj-agent-log

# View history of specific commit types
jj-agent-log-prefix "[FEAT]:"
jj-agent-log-prefix "[DOCS]:" --template "{commit_id} {description}"

# If approach is wrong, abandon it
jj-agent-abandon

# Compare different approaches
jj-agent-compare bookmark1 bookmark2

# Clean up history before sharing
jj-agent-cleanup 3  # Squash last 3 commits
```

## Testing Integration

### Using jj-agent-test Function
```fish
# Test changes with specific commands
jj-agent-test "npm test"
jj-agent-test "python -m pytest"
jj-agent-test "cargo test"

# Test results are automatically tagged and committed
```

### Testing Integration Guidelines
- Use jj-agent-test function for validation when available
- Include test results in commit messages for complex functions
- Create separate commits for test fixes vs implementation fixes
- Document test failures and resolutions in commit messages

### Example Testing Workflow
```fish
# Implement feature
jj-agent-commit "[FEAT] Add user validation function"

# Test the implementation
jj-agent-test "npm run test:validation"

# If tests pass, they're automatically committed
# If tests fail, fix and commit separately
jj-agent-commit "[FIX] Correct email validation regex"

# Re-test
jj-agent-test "npm run test:validation"
```

## Examples

### Good Implementation Sequence

Example: Adding user authentication system

1. First commit:
   ```
   [FEAT]: Add user model and database schema
   ```

2. Second commit:
   ```
   [FEAT]: Implement password hashing service
   ```

3. Third commit:
   ```
   [FEAT]: Add user registration endpoint
   ```

4. Fourth commit:
   ```
   [FEAT]: Add login/logout endpoints
   ```

5. Fifth commit:
   ```
   [TEST]: Add integration tests for auth flow
   ```

### Poor Implementation (Avoid)

Single massive commit:
```
[FEAT]: Add user authentication system

Added models, database schema, password hashing, user registration, 
login/logout, password reset, email verification, tests, etc.
```

## Troubleshooting

### Common Pitfalls

1. **Too Many Changes**: If you find yourself writing "and" multiple times in your commit message, your commit is probably doing too much.

2. **Incomplete Implementation**: If a commit requires future commits to make it work, it's likely not complete enough.

3. **Unrelated Changes**: If changes don't directly relate to the commit message, they should be in separate commits.

4. **Lack of Context**: Commit messages should provide enough context for others to understand the change without additional explanation.

### Recovery Strategies

1. If a commit contains too many changes:
   ```fish
   jj split -i  # Interactive split
   ```

2. If you need to revise a commit message:
   ```fish
   jj describe -m "New, better message"
   ```

3. If you need to go back to a previous state:
   ```bash
   # First view recent operations
   jj-agent-restore  # Without arguments shows operation history
   
   # Then restore to a specific operation
   jj-agent-restore op_id
   ```

4. If you need to find commits with specific prefixes:
   ```bash
   # Find all documentation commits
   jj-agent-log-prefix "[DOCS]:"
   
   # Find all feature commits
   jj-agent-log-prefix "[FEAT]:"
   ```

### Tool Usage Validation

**Self-validation principle**: When building agent workflow tools, immediately use them for real work:
- Creates authentic usage examples
- Discovers usability issues that testing misses
- Validates workflow assumptions through practice
- Builds confidence in the tooling

**Anti-pattern**: Building tools and then not using them defeats the purpose of creating agent-specific workflows.

Remember: Each commit should tell a clear, focused story about one change to the codebase.
