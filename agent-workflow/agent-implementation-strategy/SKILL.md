---
name: agent-implementation-strategy
description: (no description)
disable-model-invocation: true
metadata:
  status: deprecated
  superseded-by: execution-spine
---

# Agent Implementation Strategy

## Table of Contents
- [Planning Phase](#planning-phase)
- [Atomic Implementation](#atomic-implementation)
- [Testing and Verification](#testing-and-verification)
- [Repository Management](#repository-management)
- [Tool Usage Requirements](#tool-usage-requirements)
- [Documentation](#documentation)
- [Review and Iteration](#review-and-iteration)
- [Examples](#examples)

## Planning Phase

### 1. Requirement Analysis
- Thoroughly analyze the requirements before writing any code
- Identify the core functionality and expected behavior
- Distinguish between essential and optional features
- Create a mental model of the complete solution

### 2. Implementation Strategy
- Break down the task into logical, independent units of work
- Identify dependencies between components
- Plan an implementation order that builds incrementally
- Create a rough estimate of effort for each component
- Consider potential challenges and edge cases

### 3. Architecture Planning
- Choose appropriate patterns and data structures
- Plan the interfaces between components
- Consider extensibility and maintainability
- Prioritize simplicity and clarity over cleverness

## Atomic Implementation

### 1. Atomic Commit Principles
- Each commit should implement exactly ONE logical change
- A commit should leave the codebase in a working state
- Related changes across multiple files belong in the same commit
- Unrelated changes belong in separate commits, even if small

### 2. Commit Structure
- Start with infrastructure/foundational changes
- Implement core functionality before extensions
- Build vertically (complete features) rather than horizontally (partial implementations)
- Follow this sequence when possible:
  1. Data models and interfaces
  2. Core business logic
  3. Error handling and edge cases
  4. Tests
  5. Documentation

### 3. Commit Boundaries
Poor commit boundaries:
- Multiple unrelated features in one commit
- Mixing refactoring with new features
- Partial implementations that don't work on their own
- Extremely large commits that are difficult to review

Good commit boundaries:
- One new function or method with its tests
- A complete feature, however small
- A single bug fix
- A focused refactoring of one component
- Documentation for a specific feature

## Testing and Verification

### 1. Test-First Approach
- Consider writing tests before implementation
- Use tests to clarify your understanding of requirements
- Start with simple test cases, then add edge cases

### 2. Testing Each Commit
- Every commit should be independently testable
- Verify functionality works as expected before committing
- Include tests with implementation when appropriate
- Run the full test suite before finalizing

### 3. Manual Testing
- Test the user experience, not just the code
- Verify with realistic data and scenarios
- Check error states and boundary conditions

### 4. Verification Requirements
- Every function must be tested before considering implementation complete
- Include verification steps in commit messages when appropriate
- Document any limitations discovered during testing
- Use available testing tools (like jj-agent-test) for validation
- Verify that implementation matches exactly what was requested

## Repository Management

### 1. Conservative Cleanup Principle
- **Default Position**: Preserve atomic commit history unless it has obvious problems
- **Focus on real issues**: Empty commits, duplicates, file organization, bookmark clutter
- **Avoid aggressive squashing**: If squashing creates conflicts, stop and reconsider
- **Preserve development story**: Atomic commits that tell a logical progression should be kept

### 2. Cleanup Priority Order
1. **High Priority**: Empty/WIP commits, duplicate commits, broken functionality
2. **Medium Priority**: Bookmark consolidation, file structure organization
3. **Low Priority**: Commit count optimization, "prettier" history
4. **Avoid**: History rewriting that creates new problems

### 3. Problem Assessment Protocol
Before any repository cleanup:
- **Identify real problems**: Conflicts, broken functionality, development noise
- **Distinguish from perceived problems**: "Too many commits" is often not actually problematic
- **Evidence-based decisions**: Analyze what's actually causing issues vs. assumptions
- **Conservative approach**: When in doubt, preserve existing structure

## Tool Usage Requirements

### 1. Mandatory Agent Function Usage
- **Always use custom agent functions** when they exist for VCS operations
- **Don't bypass your own tools**: Use jj-agent-* functions instead of raw jj commands
- **Validate through usage**: Using tools for real work provides better validation than testing alone

### 2. Real-World Tool Validation
- **Create and immediately use**: After building agent workflow tools, use them for actual work
- **Don't just test - apply**: Real usage discovers issues that automated testing misses
- **Iterate based on experience**: Improve tools based on practical usage patterns

### 3. Consistency Benefits
- **Enforces good patterns**: Agent functions ensure consistent commit messages and workflows
- **Provides interface stability**: Wrapper functions protect against underlying tool changes
- **Enables tracking**: Built-in metrics and session management for agent work
- **Creates examples**: Real usage creates documentation through practice

## Documentation

### 1. Self-Documenting Code
- Use clear naming conventions
- Structure code for readability
- Favor explicit over implicit

### 2. Code Comments
- Explain "why" rather than "what"
- Document non-obvious design decisions
- Note potential future improvements

### 3. Implementation Notes
- For each implementation, provide:
  - A summary of what was implemented
  - Any trade-offs or design decisions made
  - Known limitations
  - Instructions for testing

## Review and Iteration

### 1. Self-Review Process
- Review your own implementation before submitting
- Question design decisions objectively
- Look for edge cases and potential issues
- Consider performance and maintainability

### 2. Iterative Improvement
- Implement feedback promptly and completely
- Make changes in new commits, not by modifying history
- Track and address all issues before considering implementation complete

### 3. Progressive Refinement
- Start with a minimal working implementation
- Iterate to improve specific aspects
- Keep iterations focused on a single improvement area
- Maintain backward compatibility when iterating

## Examples

### Example: Implementing a User Authentication System

#### Poor Implementation Strategy
Single massive commit with message "Added user authentication"
- Contains database schema, API endpoints, UI components, email services
- Mixes working and incomplete features
- No tests or documentation

#### Good Implementation Strategy
Series of focused commits:
1. "Added user model and database schema" (foundational)
2. "Implemented password hashing and verification" (core security)
3. "Added user registration endpoint" (feature 1)
4. "Added login/logout endpoints" (feature 2)
5. "Implemented JWT token generation and validation" (core auth)
6. "Added password reset functionality" (feature 3)
7. "Created integration tests for auth flow" (testing)
8. "Added authentication documentation" (docs)

### Example: Bug Fix Implementation

#### Poor Implementation Strategy
Commit message: "Fixed stuff"
- Contains unrelated fixes
- Includes refactoring not related to the bug
- No explanation of what was fixed or how

#### Good Implementation Strategy
1. "Fixed user session timeout by updating token expiry logic"
   - Contains only changes related to the specific bug
   - Includes test that verifies the fix
   - Commit message explains what was fixed and how

### Example: Refactoring Implementation

#### Poor Implementation Strategy
Single commit: "Refactored code"
- Mixes multiple refactorings
- Also includes feature changes
- No clear purpose or benefit explained

#### Good Implementation Strategy
Separate focused commits:
1. "Refactored authentication service to use dependency injection"
   - Only changes related to the DI refactoring
   - No functional changes
   - Clear explanation of benefits in commit message
2. "Simplified error handling in user controller"
   - Focused only on the error handling improvements
   - No unrelated changes

Remember: The goal of atomic implementation is to create a clear, understandable history that makes review, testing, and future maintenance easier.
