# Git and workflow boundaries — proposal

Status: partially adopted 2026-08-10; global operating-spine decision remains
provisional

Adopted decisions:

- verified local commits are authorised save-points for scoped work units;
- work uses a dedicated non-default branch or worktree by default; and
- merge, push, deployment and publication require explicit user approval.

Still under review:

- which workflow skills form the global operating spine and whether their
  references require manifest closure.

This record addresses the overlap recorded in
`skills-vcs-workflow-concerns-overlap-k5c` and the commit-authorisation gap in
`skills-commit-when-policy-gap-r8e`.

In plain English: this record decides when an agent may make a local Git
save-point for a scoped piece of work. It does not authorise sharing, merging,
deploying or publishing that work.

## Audit evidence

The initial audit found a policy gap across these files. The canonical wording
now records the adopted local-save-point rule and keeps the remaining external
operations separate:

- `coordination-protocol` now records the brief as an artefact rather than
  using ambiguous commit language.
- `execution-spine`, `git-vcs`, `git-change-manage`, `work-unit-manage`,
  `jj-vcs` and `br` now cross-reference the local-save-point and external-gate
  boundary.
- `skills-manage` no longer treats “forgetting to commit” as a generic mistake;
  the backend policy determines when a save-point is required.

The remaining policy question is the composition of the global operating
spine and whether every dependency named by a global skill must itself be
globally deployed.

## Ownership map

| Concern | Owning skill | Must not own |
|---|---|---|
| Posture, phase transitions, human decisions and readiness | `coordination-protocol` | Git commands, staging, branch mechanics, or tracker writes |
| Backend-neutral work-unit lifecycle | `work-unit-manage` | Git/JJ command syntax or harness-specific policy |
| Git work-unit shape | `git-change-manage` | Generic posture, tracker storage, or raw Git command reference |
| Git semantics and safe commands | `git-vcs` | Deciding when a unit is ready to commit or merge |
| Execution loop and evidence | `execution-spine` | Repeating Git/JJ mechanics or deciding human policy |
| Issue storage and tracker verbs | `br` | Authorising implementation commits or defining the work lifecycle |
| Ticket construction and ownership | project tracker policy / ticket skill | Git storage mechanics |

`jj-change-manage` and `jj-vcs` should mirror the Git split for the JJ backend.
They should not force a Git mental model onto JJ or make the generic lifecycle
depend on either backend.

## Normal work-unit shape

1. A ticket or explicit user request defines the outcome and boundaries.
2. The lead/supervisor confirms scope, acceptance evidence and the appropriate
   backend context.
3. The work starts in a clearly identified branch/worktree or JJ change.
4. The agent executes and verifies one coherent unit at a time.
5. The agent creates local commits that contain the verified unit. A local
   commit is a reversible work-unit boundary, not a push or merge.
6. Review examines the committed branch/change and its evidence.
7. Merge, push, deployment or publication remains a separate external action
   requiring the relevant approval.

This is the adopted normal path. A user may explicitly request a different
path; the deviation should be visible rather than silently inferred.

## Adopted local-commit policy

- A scoped work unit may create local commits as part of execution and close;
  it does not need a new conversational approval for every reversible commit.
- The commit must stay within the ticket/work-unit boundary and be inspected
  before it is created.
- A local commit does not authorise pushing, merging, force-pushing, publishing,
  or deploying.
- Tracker bookkeeping such as `.beads/` follows the same deliberate commit
  policy. The `br` skill may explain that JSONL is already exported, but it
  must not be read as blanket permission to commit implementation work.
- If work is held for review, the handoff names the branch/change and commit;
  “uncommitted for review” is not the default state.

## Migration implications

- Add the missing ownership and scope clauses to the existing skills rather
  than duplicating the entire lifecycle in each one.
- Repair or replace obsolete absolute links to the old skill location.
- Decide whether the core operating spine is global before changing the global
  manifest; a skill referenced by an active global skill must either be
  globally available or be referenced as project-scoped explicitly.
- Retain deprecated agent-commit workflow material only long enough to confirm
  that its durable guidance has been absorbed; then archive it rather than
  leaving a second live policy surface.

## Decisions still required

1. Adopt or amend the proposed local-commit rule.
2. Choose the global operating spine: the minimum candidate is
   `lead`, `supervisor`, `coordination-protocol`, `execution-spine`, and
   `work-unit-manage` alongside the existing Git/JJ adapters.
3. Decide whether the default work context is a dedicated branch/worktree or
   whether the current branch may be used when explicitly identified.
4. Define who may approve a local exception, merge, push, deployment or
   publication, and where that approval is recorded.
