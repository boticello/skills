---
name: agent-task-boundaries
description: (no description)
disable-model-invocation: true
---

# Agent Task Boundaries Guidelines

## Table of Contents
- [Core Principles](#core-principles)
- [Task Boundary Rules](#task-boundary-rules)
- [Task Lifecycle](#task-lifecycle)
- [Communication Protocol](#communication-protocol)
- [Repository Management Boundaries](#repository-management-boundaries)
- [Examples](#examples)
- [Task Boundary Checklist](#task-boundary-checklist)

## Core Principles

1. **Single-Task Focus**: Complete one clearly defined task before moving to the next.
2. **Explicit Permission**: Never proceed to a new task without clear permission.
3. **Scope Discipline**: Maintain the boundaries of the current task without scope creep.
4. **Completion Confirmation**: Confirm task completion before requesting new instructions.

## Task Boundary Rules

### 1. Task Definition and Clarification
- Begin by confirming your understanding of the task scope
- Ask clarifying questions before beginning substantive work
- Break complex tasks into logical sub-tasks, but don't begin them without confirmation
- Establish clear completion criteria for the current task

### 2. Working Within Boundaries
- Stay strictly within the defined task parameters
- Never introduce new features, files, or functionality without explicit permission
- If a task dependency is discovered, flag it but don't pursue it automatically
- When uncertain about boundaries, ask rather than assume
- Make **atomic commits** - each commit should represent a single logical change (see [Jujutsu Agent Workflow](jujutsu_agent_workflow.md#atomic-commit-guidelines))
- Separate implementation steps into distinct commits that can be reviewed individually

### 3. Task Completion
- Signal clearly when a task is completed
- Summarize what was accomplished
- Highlight any outstanding issues or concerns
- Explicitly request permission for follow-on tasks

### 4. Transitioning Between Tasks
- Never assume a logical next step
- Present options for next steps, but wait for instructions
- When a new task is assigned, confirm the previous task is fully complete
- Start each new task with a clean mental context

## Task Lifecycle

```
1. Task Assignment → 2. Scope Clarification → 3. Implementation → 
4. Completion Verification → 5. Handoff/Close
```

At each transition point, explicit confirmation is required.

## Communication Protocol

### Proper Task Boundary Signals

- **Task Completion Signal**: "✅ Task Complete: [brief summary]"
- **Boundary Question**: "⚠️ Task Boundary Check: [question about scope]"
**Next Task Request**: "⏭️ Request permission to proceed with: [next logical task]"
- **Scope Clarification Request**: "🔍 Scope Check: [specific question about boundaries]"
- **Testing Complete Signal**: "🧪 Testing Complete: [verification summary]"
- **Documentation Updated Signal**: "📝 Documentation Updated: [what was documented]"
- **Implementation Choice**: "🤔 Implementation Decision Needed: [options A vs B]"
- **Problem Assessment Request**: "🔍 Problem Assessment: [analysis of actual vs perceived issues]"

### Improper Boundary Crossing Signals

- Starting work on unassigned tasks
- Implementing features beyond current scope
- Making architectural decisions beyond immediate requirements
- Adding functionality "because it might be useful later"
- Bundling multiple logical changes in a single commit
- Working on multiple tasks simultaneously without clear separation

## Examples

### Proper Boundary Management:
```
Human: Add a function to parse CSV files.
Agent: I'll implement a CSV parsing function. Should it handle quoted fields and escape characters?
Human: Yes, please handle those.
Agent: [Implements CSV parser]
Agent: ✅ Task Complete: CSV parser implemented with support for quoted fields and escaping.
Agent: ⏭️ Request permission to proceed with: Adding tests for the CSV parser?
Human: Yes, please add tests.
Agent: [Begins test implementation]
```

### Improper Boundary Crossing:
```
Human: Add a function to parse CSV files.
Agent: [Implements CSV parser]
Agent: I've also added a JSON parser since you might need that too, and a file selection dialog to choose input files.
Human: I didn't ask for those additional features.
```

## Repository Management Boundaries

### 1. Problem Assessment Protocol
Before proposing repository cleanup or changes:

**Mandatory Assessment Steps:**
- **Identify real problems**: Broken functionality, conflicts, empty commits, development noise
- **Distinguish perceived problems**: "Too many commits" vs. actual issues affecting work
- **Evidence-based analysis**: What specifically is causing problems vs. assumptions
- **Conservative default**: Preserve existing structure unless clearly problematic

### 2. Repository Cleanup Boundaries
**High Priority Issues (address immediately):**
- Broken functionality or conflicts
- Empty/WIP commits with no content
- Duplicate commits from merge conflicts
- File organization problems

**Medium Priority Issues (address with permission):**
- Bookmark consolidation and organization
- Directory structure improvements
- Temporary file cleanup

**Low Priority Issues (avoid unless specifically requested):**
- Commit count "optimization"
- History "prettification" 
- Aggressive squashing for aesthetic reasons

**Forbidden Actions (require explicit permission):**
- History rewriting that creates conflicts
- Squashing atomic commits that tell a clear story
- Removing development context that aids understanding

### 3. Tool Usage Boundaries
**Mandatory Consistency:**
- Always use agent-specific functions when they exist
- Don't bypass custom workflows with raw commands
- Validate tools through real usage, not just testing

**Boundary Violation Examples:**
- Building jj-agent functions but using raw `jj` commands
- Creating workflows but not following them
- Testing tools without using them for actual work

## Task Boundary Checklist

Before starting a new task or subtask, verify:

- [x] You have explicit permission for this specific task
- [x] The scope is clearly defined and understood
- [x] Previous tasks are properly completed and closed
- [x] You understand what constitutes completion
- [x] You know when to seek further guidance
- [x] You can identify the logical, atomic units of work
- [x] Have I received explicit permission for this specific implementation?
- [x] Do I understand what "done" looks like for this task?
- [x] Have I clarified any implementation choices with the user?
- [x] If this involves repository changes, have I assessed real vs. perceived problems?
- [x] Will I use appropriate agent functions instead of bypassing my own tools?


Before considering a task complete, verify:

- [x] All requested functionality is implemented
- [x] The implementation stays within requested scope
- [x] You've provided a clear summary of what was done
- [x] You've explicitly requested next steps
- [x] Your commits are atomic and represent logical units of work
- [x] Each implementation step is independently reviewable
- [x] Have I tested the implementation?
- [x] Does the implementation match exactly what was requested?
- [x] Am I ready to demonstrate that it works?
- [x] If repository work was involved, did I follow conservative cleanup principles?
- [x] Did I use my own agent tools for the work (validating them through usage)?


Remember: When in doubt, maintain current boundaries and seek clarification.
