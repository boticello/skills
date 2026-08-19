You are writing a verification plan for a Go coding slice.

Your job is to produce a verification plan that helps a reviewer assess the implementation properly after the coding is done. This is not a mirror of the implementation plan and not a restatement of the implementation steps. It must be written from the reviewer’s perspective.

Use the supplied verification-plan template.

Inputs you should assume are available:
- the implementation plan for the slice
- the design doc
- any relevant retros or prior verification reports
- the intended code area and source references

Goals:
- Define how a reviewer will check the slice thoroughly.
- Put the highest-value cross-cutting checks first.
- Make test depth visible and assessable.
- Provide concrete integration verification commands where relevant.
- Help the reviewer catch architectural smells, thin tests, and behavioural regressions.

Important constraints:
- Do not simply copy the implementation plan step by step.
- Do not turn this into a giant checklist that can be ticked without reading code.
- Do not assume “tests pass” means the slice is good.
- Do not focus only on happy-path integration checks.
- Do not omit cross-cutting smells just because they are not tied to a single deliverable.

What good looks like:
- Cross-cutting checks come before per-deliverable review.
- Cross-cutting checks are informed by previous retros and known failure modes.
- The plan tells the reviewer what files or areas to inspect for each review section.
- Test depth is represented as a table with target coverage/adequacy by package or area.
- Integration verification uses concrete commands and expected outcomes.
- The reviewer can reach a clear verdict: ready, or needs fixes with specific items.
- The plan checks both behaviour and code quality.

Cross-cutting issues to consider where relevant:
- `os.Exit` outside `main()`
- `context.Background()` in CLI handlers instead of `cmd.Context()`
- print-and-exit instead of returning errors
- missing error wrapping/context
- untested service methods
- fake/mock coverage missing where architecture expects seams
- deprecated stdlib usage
- behaviour matched but implementation copied wrongly from Ruby or another source
- production/test safety boundaries
- external dependency assumptions and error messages

When deciding what to include, prefer:
- reviewer questions over implementer instructions
- code smells over step narration
- adequacy assessment over test counting
- commands with expected results over vague “verify it works”
- file/area inspection guidance over generic advice

Before finalising, check your own draft against these failure modes:
1. Is this just the implementation plan rewritten as review steps?
2. Can a reviewer tick boxes without really inspecting the code?
3. Have I surfaced cross-cutting risks first?
4. Have I made test depth explicit?
5. Do the verification commands actually test the acceptance criteria?
6. Would this catch the kind of process failures seen in prior slices?
7. Does the plan end in a usable verdict section with specific fix categories?

Output only the completed verification plan in markdown, using the supplied template.
