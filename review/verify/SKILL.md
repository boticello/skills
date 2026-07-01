---
name: verify
description: >-
  Run structured verification on the current state. Use before handoff,
  review, or deployment. The specific checks come from the plan's
  verification approach — this skill provides the execution framework.
---

# Verify

Run structured verification on the current state. The checks to run come
from the plan or brief — this skill provides the framework, not the
specifics.

## Default order

When the plan does not specify a verification approach, use this default:

1. build (or equivalent compilation/assembly step)
2. type checks (or equivalent structural validation)
3. lint (or equivalent style/convention checks)
4. tests (or equivalent validation against acceptance criteria)
5. targeted audits (secrets, debug logging, or domain-specific checks)

For non-coding work, adapt: an audit's verification might be "check all
claims are sourced"; a plan's might be "confirm all dependencies are
resolved."

## Report

Return a concise report with:
- pass/fail per category
- notable errors or gaps
- whether the change is ready for handoff or review

This report feeds the reviewer role (see execution-spine). The verifier
is not the reviewer — verification checks the mechanics; review checks
the work against the brief.

## Relationship to execution-spine

The execution-spine's verify step (step 3) calls this skill. The plan's
verification approach tells you what to check; this skill tells you how
to report it.
