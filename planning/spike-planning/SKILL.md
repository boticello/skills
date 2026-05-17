---
name: spike-planning
description: "Write a structured implementation plan for a spike or small feature. Produces two documents: an implementation plan for the builder and a verification plan for the reviewer. Use before handing work to an implementing agent."
---

# Spike Planning

This skill produces two documents from one thinking process:

1. **Implementation plan** — what the builder reads and follows
2. **Verification plan** — what the reviewer checks after implementation

Both documents share the same structure (steps, gates, risks) but serve different audiences and different moments in the workflow.

## Workflow

### 1. Read and explore

Before writing anything, read:

- The relevant domain skill (e.g. `go-development` for Go work)
- The existing implementation being matched or replaced (e.g. Ruby source for behavioural compatibility)
- Any local reference docs (SDK docs, command references, architecture docs)
- Any existing risk analysis or related working material

Do not skimp on this step. Gaps in the plan come from gaps in reading. The me2 spike's `SELECT 1` error came from not reading SurrealQL docs carefully enough.

### 2. Decompose into slices

Break the work into the thinnest possible slices. Each slice should:

- Produce one commit
- Have a clear gate (what "done" looks like)
- Be verifiable independently

Slice decomposition rules:

- Start with the thinnest possible vertical slice that proves the toolchain works (scaffold → build → ci green)
- Add one capability per slice after that
- Each slice should be small enough that if it goes wrong, you lose at most one slice's work
- Order slices so earlier slices create foundations that later slices depend on (never the reverse)

### 3. Identify risks per slice

For each slice, name:

- What could go wrong
- How to prevent it
- What to check at the gate

### 4. Write the implementation plan

Use the template below. Fill in every section. Leave nothing vague — "tests pass" is not a gate; "RunQuery returns correct JSON with a fake Querier" is a gate.

### 5. Derive the verification plan

The verification plan mirrors the implementation plan but is written for a **different agent** who did not write the code. It contains:

- The same step structure
- Specific things to check at each step (not just "does it work")
- Language-specific review checks (e.g. "no `os.Exit` outside `main()`" for Go)
- Test depth checks (e.g. "every service method has a test with a fake")
- Integration verification (does it actually run against the real test target?)

### 6. Write the handoff preamble

The handoff preamble goes at the top of the implementation plan. It tells the builder:

- Which branch to work on
- Which skills to read first
- Which reference docs to read (specific file paths, not "read the docs")
- What not to touch (production databases, unrelated branches, stashed work)

This is not a separate document. It is the opening section of the plan.

### 7. Consider the soul

Some guidance is about *how to work*, not *what to build*. Consider whether the plan needs a short preamble about posture:

- "Read everything before writing code."
- "Commit after each step. Each commit should compile and pass CI."
- "If you're unsure, check the existing implementation and copy its pattern."

This can go in the handoff preamble or in a separate file referenced by the plan. If it's reusable across plans, put it in a skill or a repo-level doc. If it's specific to this plan, put it in the preamble.

---

## Implementation Plan Template

```markdown
# [Title]: [What this builds]

## Why

[One paragraph: what problem this solves and why this approach.]

## What this proves

[Numbered list of concrete, verifiable outcomes. Each one becomes a row in the success criteria table.]

## Safety

[What database/environment to use. What to never touch. Any credentials or access constraints.]

## Prerequisites

- [ ] [Completed items before implementation starts — skills, branches, tooling, test data]

## Required reading (read all before writing code)

1. **Process:** [skill name] — [what it covers]
2. **Existing implementation:** [file paths to the code being matched or replaced]
3. **Reference docs:** [specific file paths to SDK docs, command references, architecture docs]

## Risk summary

| Slice | Risk | Key concern | Mitigation |
|-------|------|-------------|------------|
| [name] | [Low/Medium/High] | [what could go wrong] | [how to prevent it] |

## Architecture

[Repo structure, key interfaces, mocking strategy. Specific enough that the builder knows what files to create and how they connect.]

## Command surface (if CLI)

[Exact commands, flags, exit codes, output shape. Reference the existing implementation for behavioural compatibility.]

## Implementation steps

### Step 0: [Name]

- [Specific files to create, with purpose]
- [Specific tests to write]
- **Gate:** [exact, verifiable condition]

[Repeat for each step.]

## Success criteria

| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | [concrete outcome] | [exact verification step] |

## State

- Branch: [name]
- [Any context about stashed work, unrelated branches, etc.]
```

---

## Verification Plan Template

```markdown
# Verification: [Title]

## Context

[Branch name, what was built, link to the implementation plan.]

## Setup

- Branch: [name]
- Binary/output location: [path]
- Test target: [e.g. test database, localhost, etc.]

## Per-step review

### Step [N]: [Name]

**Files to review:** [list]

Check:
- [ ] [Specific code quality check — e.g. "no os.Exit outside main()"]
- [ ] [Specific test depth check — e.g. "service method has a fake Querier test"]
- [ ] [Specific behaviour check — e.g. "backup path derives from database name"]
- [ ] Gate passed: [exact condition from the plan]

[Repeat for each step.]

## Cross-cutting checks

These apply to the whole codebase, not a single step:

- [ ] No language anti-patterns carried over from the source implementation (e.g. Ruby `exit` → Go `os.Exit` in Cobra handlers)
- [ ] Every interface/seam defined in the plan has at least one test with a fake
- [ ] No deprecated stdlib usage
- [ ] Error handling is consistent (return errors, don't print-and-exit)
- [ ] `context.Context` used correctly throughout (cmd.Context() in CLI handlers)
- [ ] External dependencies are documented (e.g. `surreal` CLI for backup)
- [ ] No production data was touched
- [ ] Binary runs and produces correct output

## Integration verification

[Specific commands to run against the real test target. Not "try it" — exact commands with expected output shape.]

| Command | Expected result |
|---------|----------------|
| [exact command] | [expected output or outcome] |

## Test depth assessment

For each service/core package, assess:

| Package | Pure function tests | Fake/mock tests | Integration tests | Assessment |
|---------|-------------------|-----------------|-------------------|------------|
| [name] | [count] | [count] | [count] | [Adequate / Thin / Missing] |

If any package is "Thin" or "Missing", list what tests should be added.

## Verdict

- [ ] Implementation matches the plan
- [ ] Tests are adequate
- [ ] No anti-patterns
- [ ] Integration verified
- [ ] Ready for use / needs fixes: [specific items]
```

---

## Heuristics

- **Be specific.** "Test input resolution" is weak. "Test ResolveQueryInput with args, file, stdin, empty input, missing file" is strong.
- **Write gates you can run.** "task ci green" is a gate. "Architecture is clean" is not a gate.
- **Name the language accent.** If the builder is translating from another language, name the specific patterns that don't carry over (Ruby `exit` → Go return errors, Python `try/except` → Go `if err != nil`).
- **Define test depth.** Say what "enough tests" means for each slice. The builder will not write tests you didn't ask for.
- **Include a review stage as the last step.** The implementing agent cannot see its own accent. A separate review pass catches what the builder normalises.
- **Keep the plan and the verification plan in sync.** They share the same step structure. If you add a step to the plan, add the corresponding review checks to the verification plan.
- **Put the handoff in the plan, not in a separate document.** The handoff preamble and the plan are one document. The builder reads one thing.
