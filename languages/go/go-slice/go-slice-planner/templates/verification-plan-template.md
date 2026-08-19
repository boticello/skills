# Verification: [Slice N]

## Setup
[branch, working directory, build command]

## Cross-cutting checks
- [ ] [smell: os.Exit, context.Background, etc.]

## Per-deliverable review

### Deliverable 1
**Files:** [list]
- [ ] [contract item: does X produce Y?]
- [ ] [test coverage: TestFoo covers cases A, B, C]
- [ ] Gate passed

## Test depth assessment
| Area | Pure function tests | Fake/mock tests | Integration tests | Adequacy |
|------|---------------------|-----------------|-------------------|----------|
| [area] | [expectation] | [expectation] | [expectation] | [adequate / thin / missing / unclear] |

## Integration verification
| Command | Expected result |
|---------|----------------|

## Gate reproducibility
For each gate command, record who ran it, the result, and whether the reviewer independently reproduced it. If independent reproduction is not possible, state why and identify the captured implementer evidence reviewed.

| Command | Who ran it | Result | Independently reproduced? |
|---------|------------|--------|---------------------------|
| `[command]` | Implementer / Reviewer | [capture] | yes / no — [reason if no] |

## Verdict
- [ ] Ready / needs fixes: [list]
