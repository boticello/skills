---
name: remind-management
description: Use when scoping, clarifying, or managing reminder-like support, including reminders, routines, rituals, habits, checklists, event-linked prompts, and people-linked reminders.
exclude_tools:
  - claude_code
  - craft_agents
---

# Remind Management

Use this skill when the user asks to view, add, design, or manage reminder-like support.

This skill is currently provisional.

It should not assume that every request is:
- a plain due-date reminder
- a `remind` tool action
- or a ticket in disguise

Instead, its first job is to classify the request correctly.

## Purpose

This skill helps the agent determine what kind of temporal-support object the user is actually dealing with and what current system surfaces are relevant.

It is therefore partly:
- a capability skill
- a clarification skill
- a temporary guide while the underlying reminder, routine, and people-support model is still being worked out

## Object classes to consider

When a user asks for reminder-related help, first determine whether the request is mainly about:
- a reminder
- a ticket or task
- a routine or rhythm
- a ritual
- a habit
- a checklist
- an event
- a person-linked reminder
- a review reminder

## Current useful surfaces

- `me tk show <id> --json`
- `me tk list`
- `me search`
- `me jot`
- calendar/event systems where relevant
- any current `remind` files or scripts if the request is truly about the legacy `remind` path

## Clarification workflow

1. Determine the object class before choosing a tool.
2. Clarify the trigger mode:
   - hard datetime
   - date-only
   - cadence or interval
   - event-relative
   - salience-based
3. Clarify whether the prompt should point to another object:
   - ticket
   - routine
   - ritual
   - checklist
   - event
   - person/relationship context
4. Decide whether the request is:
   - immediate operational work using current tools
   - design work on the reminder system itself
   - or a mixed case requiring both
5. Use current tools carefully without pretending the current model is already final.

## Decision rules

- Do not collapse every reminder-like request into a task or ticket.
- Do not assume the `remind` Unix tool is the final answer.
- Treat routines, rituals, habits, and checklists as distinct concepts when that distinction matters.
- Treat people-linked reminders as relational and often emotionally salient, not as plain due-date tasks.
- Treat review/self-care/orientation reminders as part of the broader rhythm system.
- If the request is really about system design rather than immediate operation, say so explicitly and work at the design level first.

## Good patterns

```bash
me tk show 84 --json
me tk show 87 --json
me search "reminder"
me jot -k reflection "This looks more like a routine or person reminder than a plain due-date reminder."
```

## Output pattern

A good output from this skill should include:
- the object class you think you are dealing with
- the trigger mode
- any linked objects or systems involved
- whether the request is operational, design-focused, or mixed
- the next concrete action or design clarification needed
