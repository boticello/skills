---
name: lark-crm
description: >-
  Manage the Lark Base CRM for the solo IT contractor business — create and
  update Opportunities, log Activities, move pipeline stages, query open tasks,
  chain activity sequences, and resolve linked People/Organisations. The agent
  operates under the Lark app tenant identity (tenant_access_token), so there is
  full Base read/write but NO personal calendar access. Trigger when the user
  mentions opportunities, pipeline, activities, interviews, contacts,
  recruiters, applications, or recruitment.
license: MIT
domain: crm
role: specialist
scope: operations
output-format: tool-calls
triggers:
  - lark-crm
  - crm
  - opportunity
  - opportunities
  - pipeline
  - activity
  - activities
  - stage
  - recruiter
  - recruitment
  - interview
  - cover note
  - IR35
  - open tasks
  - follow up
  - chase
---

# Lark CRM

This skill drives a solo IT contractor CRM held in a Lark (Feishu) Base. All
operations go through the `lark-crm` MCP server. lark-mcp registers tools under
**snake_case** names — primarily
`bitable_v1_appTableRecord_{search,list,get,create,update,batchCreate,batchUpdate}`.
(Note: the dotted form `bitable.v1.appTableRecord.search` appears in some docs,
but the wire name the MCP client sees is snake_case.)

**Argument shape:** tool calls use the Lark OpenAPI envelope — `app_token` and
`table_id` go inside a `path` object, pagination in `params`, and record data
or filters in `data`. Example for search:
`{"path":{"app_token":"...","table_id":"..."},"params":{"page_size":20},"data":{"filter":{...}}}`.

**Token mode:** tenant (app/bot). Calendar tools are NOT available; if the user
asks for a calendar event, say so and note it as a deferred follow-up (see
"Limitations & deferred" below).

## CRM identifiers

These never change — record once, reference forever.

### Base app
- **APP_TOKEN:** `TB2MboGebaNiSCs8Bmqj8bHlprb`

### Tables
| Table | `table_id` |
|---|---|
| Organisations | `tblvbZpzWEVOEHAk` |
| People | `tblmPM6YJttm4MeQ` |
| Opportunities | `tblCfgQmxQeGyEph` |
| Activities | `tblcZc7YAP7HNBf9` |

All Bitable tool calls require `app_token` (the APP_TOKEN above) and the
relevant `table_id` as parameters, plus a `fields` object for record data.

## Schema — verified live field names

The field names below are the **exact** names the Lark API expects. They were
last reconciled against the live Base on 2026-06-17 via
`bitable_v1_appTableField_list`. Lark search/sort calls reject wrong casing
(`Due date` ≠ `Due Date`), so copy field names verbatim from here. If a call
fails with `InvalidSort` / `InvalidFilter` / `not found field_name`, the schema
has drifted — re-run `bitable_v1_appTableField_list` on the table and correct
this section.

**Schema changes are UI-only.** The `lark-crm` MCP exposes field *list* but not
field create/update/delete. Adding, renaming, retyping, or removing any field —
or changing a select's options — must be done by the **user in the Lark Base
UI**. When the user confirms a schema change, re-run
`bitable_v1_appTableField_list` to read the new state, then update this section
to match before any further record operations. Never assume a changed field is
writable until it appears in the live field list.

### Opportunities (`tblCfgQmxQeGyEph`)

| Field | ui_type | Valid values / shape |
|---|---|---|
| `Title` | Text | Free text — the opportunity name |
| `Code` | Number | Internal number |
| `Type` | SingleSelect | Permanent / Contract / Business Opportunity |
| `Stage` | SingleSelect | New / Applied / In Progress / Offer / Won / Lost / On Hold |
| `Status` | SingleSelect | Cancelled / In Progress — **redundant with `Stage`; `Stage` is authoritative. Use `Status` only to annotate a cancellation reason when `Stage = Cancelled`.** |
| `Client` | DuplexLink → Organisations | single; `record_ids` |
| `Primary Contact` | DuplexLink → People | single; `record_ids` |
| `Rate` | Currency (GBP) | Number |
| `Value` | Currency (GBP) | Number |
| `Terms` | MultiSelect | Inside IR35 / Outside IR35 / Employment / Fixed-Term Contract / Rolling Contract |
| `Duration` | Text | e.g. "6 months" |
| `Desirability` | Rating | 1–5 |
| `Opportunity Date` | DateTime | epoch ms |
| `Start Date` | DateTime | epoch ms |
| `JD` | Attachment | file_token (upload not available via MCP — store URL/note) |
| `CV` | Attachment | file_token |
| `Proposals` | Attachment | file_token |
| `Summary` | Text | Free text |
| `Activities` | DupexLink → Activities | back-field, read-only (managed from the Activity side) |

### Activities (`tblcZc7YAP7HNBf9`)

| Field | ui_type | Valid values / shape |
|---|---|---|
| `Activity Name` | Text | Free text |
| `Activity Type` | SingleSelect | Interview / Message / Call / Submission / Task / Chase |
| `Status` | SingleSelect | Open / Done / Cancelled |
| `Outcome` | SingleSelect | Positive / Negative / Neutral / Pending |
| `Due Date` | DateTime | epoch ms |
| `Opportunity` | DuplexLink → Opportunities | `record_ids` |
| `Person` | DuplexLink → People | `record_ids` |
| `Notes` | Text | Free text — use for interview/debrief summaries |
| `Next Activity` | SingleLink → Activities | single; forward pointer to the *next pending* step only |
| `Created` | CreatedTime | auto |

> **No `Organisation` field exists on Activities.** (A previous version of this
> doc listed one.) Organisation context comes via the linked Person/Opportunity.

### People (`tblmPM6YJttm4MeQ`)

| Field | ui_type | Valid values / shape |
|---|---|---|
| `Name` | Text | Free text |
| `Role` | MultiSelect | Recruiter / Client |
| `Organisation` | DuplexLink → Organisations | `record_ids` |
| `Opportunity` | DuplexLink → Opportunities | back-field, often populated via the Broker relationship |
| `Activity` | DuplexLink → Activities | back-field |
| `Link` | Url | e.g. LinkedIn |
| `Summary` | Text | Free text |

> No `Email` / `Phone` fields exist. Do not invent them; capture contact details in `Summary` free text if needed.

### Organisations (`tblvbZpzWEVOEHAk`)

| Field | ui_type | Valid values / shape |
|---|---|---|
| `Name` | Text | Free text |
| `Person` | DuplexLink → People | back-field |
| `Opportunity` | DuplexLink → Opportunities | back-field |

> Sparse — **no `Type` or `Notes` field.** Infer client-vs-recruiter from the
> linked Person's `Role`, not from the Organisation.

## Stage lifecycle rules

`Stage` values are: New / Applied / In Progress / Offer / Won / Lost / On Hold.

- **Contract via recruiter:** New → Applied (CV sent) → In Progress (interviews) → Offer → Won / Lost
- **Permanent:** New → Applied (application) → In Progress (interviews) → Offer → Won / Lost
- **Business opportunity:** New → Applied (proposal) → In Progress (feedback loop) → Offer (verbal) → Won / Lost
- **On Hold** may be set from any active stage when paused/ghosted.
- **Waiting for a response** (e.g. after interview) is **not** a separate stage —
  it stays at `In Progress`. There is no dedicated prose-status field; do not
  overload `Summary` as a status line (it's for the opportunity description).
  Use the open Activities query (`Status = Open`) to see what's being awaited.

## Mandatory fields by operation

- **Create Opportunity:** `Title`, `Type`, `Stage` (default `New`)
- **Create Activity:** `Activity Name`, `Activity Type`, `Status` (default `Open`), `Opportunity` link
- **Mark Activity Done:** set `Status = Done`, set `Outcome`; ask the user about a follow-up
- **Move Stage:** confirm current `Stage` before updating; never skip stages without explicit user confirmation

## Write conventions (Lark field encoding)

These shapes are **not** guessable and have cost retries. Use exactly:

| Field type | On write (`create`/`update`) | On read |
|---|---|---|
| **Text** (`Title`, `Activity Name`, `Notes`, `Summary`, …) | **plain string**: `"foo"` | array of `{text, type}` segments — read `fields["X"][0].text` |
| **Link / DuplexLink** (`Opportunity`, `Person`, `Client`, `Next Activity`, …) | **bare array of ids**: `["recXXXX"]` | object `{record_ids:[...]}}` or `{link_record_ids:[...]}` — fetch each id to get a name |
| **SingleSelect / MultiSelect** | select: `"Interview"`; multi: `["Outside IR35","Rolling Contract"]` | same |
| **DateTime** | **epoch milliseconds** (e.g. `1781703000000` for 2026-06-17 13:30 BST) | epoch ms |
| **Currency / Number / Rating** | JSON number | number |
| **Attachment** | `file_token` only — **upload not available via MCP**; store a URL/note instead | array with `file_token`, `name`, `tmp_url` |

Gotchas hit in practice:
- DuplexLink on **write** wants a bare array `["rec…"]`, **not** `{"record_ids":[…]}` (that shape is the *read* shape, and search-filter inputs differ again).
- Text on **write** wants a plain string, **not** the `[{text, type}]` segments you get back on read.
- `search` returns link fields as `{link_record_ids:[…]}` (no names). To show a
  human-readable name you must fetch the linked record. See the resolve recipe
  below.

### Resolve-and-display recipe

A single activity/opportunity read comes back as bare ids for its links. To
present it human-readably without a chain of failed filters:

1. Read the record → collect the `record_ids` from each link field.
2. For each linked table, do **one** `bitable_v1_appTableRecord_search` filtered
   by the primary text field (`Title` / `Name` / `Activity Name`), or simpler:
   read by `record_id` if a `get` tool is available. Batch these in parallel —
   one tool block, multiple calls.
3. Do **not** try to filter a linked table by the *linking* field name (e.g.
   filtering People by `Activity Name`) — that field doesn't exist on the
   target table.

To list all records cheaply when you need names + ids together (no filter),
`search` with a tautological filter like
`{field_name:"<primary text field>", operator:"isNot", value:["__none__"]}` —
this returns rows with their primary field populated. (Bare unfiltered `search`
is also fine if supported by the server.)

## Guardrails

1. **Search before create.** Before creating any linked record (e.g. Opportunity
   → End client), search the target table first with
   `bitable_v1_appTableRecord_search` to find an existing record. Only create a
   new record if the user confirms none exists. Present ambiguous matches and
   let the user choose.
2. **No auto Won/Lost.** Never set `Stage` to `Won` or `Lost` without explicit
   user confirmation, and flag any request to skip stages (e.g. New → Won).
3. **Calendar is out of scope.** Tenant token cannot create calendar events. If
   the user wants a calendar event, state this plainly and record the Activity
   (which a Base automation could later promote to a calendar event — see the
   CRM README). Do not silently drop the request.
4. **No invented values.** If a mandatory field is missing, ask for it before
   calling any write API. Never fabricate placeholder values.
5. **Resolve record_ids before linking.** When chaining activities (`Next
   Activity`) or linking any record, obtain the target `record_id` from a prior
   search/create call before writing it into the parent's link field. Links are
   written as **bare id arrays** (`["rec…"]`), not objects.

## Canonical workflows

### Create an Opportunity
1. Search Organisations for the client → `record_id`, or create (with user
   confirmation) if missing. (No `Type` field on Orgs — infer from Person `Role`.)
2. Search People for the primary contact → `record_id`, or create.
3. `bitable_v1_appTableRecord_create` on `tblCfgQmxQeGyEph` (Opportunities)
   with `Title`, `Type`, `Stage`, and links as **bare id arrays**:
   `"Client": ["recXXXX"]`, `"Primary Contact": ["recYYYY"]`.

### Log a completed Activity (interview/call/submission outcome)
1. Search Opportunities by `Title` → `record_id`.
2. Search People by `Name` → `record_id` (only if a person is involved).
3. Create the Activity with `Status = Done`, `Outcome` set, `Notes` from the
   user's free text, links as bare id arrays: `"Opportunity": ["rec…"]`,
   `"Person": ["rec…"]`.
4. If the user specifies a follow-up, create a second Activity (`Status = Open`,
   `Activity Type = Chase`/`Task`, `Due Date` set) linked to the same
   Opportunity. Optionally set the original Activity's `Next Activity` → the
   new activity **only if** it represents the next pending step. A debrief call
   is a sibling of the interview, not a child — do not use `Next Activity` for
   it (see "Record a recruiter debrief" below).

### Record a recruiter debrief (recurring pattern for contract roles)
An interview is often followed by a debrief call with the recruiter. Model
this as **its own Activity**, `Activity Type = Call`, linked to the recruiter
(Person) and the Opportunity, with the debrief notes in `Notes`. It is a
sibling of the interview, **not** a child — the interview→debrief link is
currently implicit (same opportunity, same/adjacent date), not structural.
`Next Activity` is the wrong slot for it (it points forward to a pending step).

### Move a Stage
1. Search Opportunities by `Title`, confirm current `Stage`.
2. If the requested transition skips stages, surface that and confirm.
3. `bitable_v1_appTableRecord_update` on the Opportunity's `Stage` field only.

### Query open tasks
`bitable_v1_appTableRecord_search` on `tblcZc7YAP7HNBf9` (Activities), filter
`Status` is `Open` (and optionally `Due Date` on/before a date), sort by
`Due Date` ascending. Links return as ids — resolve Opportunity `Title` and
Person `Name` in parallel before presenting (see resolve recipe above). Group
by Opportunity when presenting.

## Tool reference

Snake_case wire names (what the MCP client calls):

| Operation | MCP tool |
|---|---|
| Search records (filter) | `bitable_v1_appTableRecord_search` |
| List records (paginated) | `bitable_v1_appTableRecord_list` |
| Get one record | `bitable_v1_appTableRecord_get` |
| Create one record | `bitable_v1_appTableRecord_create` |
| Create multiple records | `bitable_v1_appTableRecord_batchCreate` |
| Update one record | `bitable_v1_appTableRecord_update` |
| Update multiple records | `bitable_v1_appTableRecord_batchUpdate` |
| List tables in the Base | `bitable_v1_appTable_list` |
| List fields of a table | `bitable_v1_appTableField_list` |

All record tools require `path: {app_token, table_id}`. Record data goes in
`data: {fields: {...}}` for create/update, and `data: {filter, sort}` for
search. Paginate with `params: {page_size, page_token}`.

## Limitations & deferred

These are **decision records, not a backlog** — see `references/MAINTENANCE.md`
for the reasoning and the conditions under which each could be revisited. Do
not act on a deferred item without re-confirming the original trade-off still
holds.

- **No calendar** under tenant token. The user-token/OAuth path expires every
  ~2h, and in a headless stdio MCP server there's no clean way to refresh
  mid-session — so calendar stays parked until the refresh problem is solved.
  See MAINTENANCE.md "Decision record: tenant token" before touching this.
- **No file upload/download** (MCP limitation). JDs/CVs as attachments stay in
  the cv workspace; the CRM stores them as a URL or note.

## Maintenance & extension

For adding the integration to a new harness, the lark-mcp gotchas (wrong preset
name, snake_case wire names, OpenAPI envelope shape, the MCP probe recipe), and
the wrapper-is-untracked caveat, read **`references/MAINTENANCE.md`**. Read it
*before* any harness-wiring or automation task — it exists to prevent repeat
traps documented from the initial setup.

## Workspace seam

The CRM owns structured state (Opportunity / Person / Organisation / Activity).
The companion cv workspace (`/Users/bear/Me/workspace/professional/active/cv`)
owns the tailored-CV artefact per opportunity, under
`applications/YYYY-MM-DD-slug/`. Link the two by recording the application slug
in the Opportunity's `Summary` or `Notes`-adjacent free text (there is no
dedicated slug field). JDs and tailored CVs live as **Attachments** on the
Opportunity (`JD`, `CV` fields) — but attachments can only be populated in the
Base UI, **not** via this MCP (no upload). So in practice: keep the tailored-CV
binary in the cv workspace, and store a reference (path or URL) in the
Opportunity `Summary`. Per-application prose status notes live in the cv
workspace's `notes.md`; structured pipeline state lives here.
