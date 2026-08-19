# Slice N: [Name]

## What this proves
1. [Structural claim about the codebase]
2. [Structural claim]

## Prerequisites — read all before writing code
- [ ] go-development skill
- [ ] [file path] — [one clause: why, not what it says]
- [ ] [file path] — [why]

## Previous-slice input status
| Input | Status | Applied lesson |
|-------|--------|----------------|
| [previous retro] | [read / absent / not applicable] | [what changes in this plan, or "none"] |
| [previous verification] | [read / absent / not applicable] | [what changes in this plan, or "none"] |

## Deliverable 1: [Name]

### Contract
**Input:** [JSON example or description]
**Output:** [JSON example or description]
**Behaviour:** [bullet list of rules, not implementation]

### What to read
- `[path]` — [why: the behaviour being replaced/matched]
- `[path]` — [why: the interface being extended/used]

### Gate
`[single verifiable command]`. Commit.

## Deliverable 2: [Name]
[same structure]

## Acceptance criteria
| # | Criterion | How to verify |
|---|-----------|---------------|
| 1 | [claim] | [command or observation] |

## Test depth expectations
| Area | Pure function tests | Fake/mock tests | Integration tests | Expectation |
|------|---------------------|-----------------|-------------------|-------------|
| [area] | [required / N/A] | [required / N/A] | [required / N/A] | [minimum adequate coverage] |

## Gate reproducibility expectations
Each required gate should record enough evidence for review. Capture the command, runner, result, and any output needed to evaluate failures or restricted-review situations.

| Gate | Command | Runner | Evidence to capture |
|------|---------|--------|---------------------|
| [gate name] | `[command]` | Implementer | [pass/fail, relevant output, notes] |

## What this does NOT do
- [explicit exclusion]
- [explicit exclusion]
