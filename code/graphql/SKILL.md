---
name: graphql
description: Write and maintain clients for GraphQL APIs — queries, pagination, error handling, and offline testing of GraphQL requests. Use whenever the user asks to call or integrate a GraphQL API, write a GraphQL client or adapter, stub or fixture GraphQL responses in tests, or debug a GraphQL request that fails in code but works in curl.
triggers:
  - GraphQL client
  - write a GraphQL query
  - pagination cursor
  - stub GraphQL responses
  - GraphQL 500
  - works in curl but not in code
---

# graphql — GraphQL client policy

## Principles

1. Author every operation as a **named query in source control**, one query
   per purpose. Operation names must match `[_A-Za-z][_0-9A-Za-z]*`; anything
   else is rejected by servers.
2. **Paginate every list connection**: loop on `pageInfo.hasNextPage` /
   `endCursor` until complete. Test pagination against fixture data with at
   least two pages.
3. **Select only fields the code consumes.**
4. **Convert responses to plain data structures once, at the adapter.**
   Preserve the distinction between missing, null, and empty values in
   downstream code. Protocol checks stay in the adapter.

## Adapter boundary

The adapter owns authentication, execution, timeouts, and error reporting.
Error messages must identify the operation and variables that produced them.

## Offline test suite

Run the real client stack (parsing, validation) offline against a local SDL
schema file, with canned JSON responses served through a stubbed transport
and routed by operation name. This detects mistyped fields and query-shape
drift without network access or credentials.

## Stub requirements

- A stub **must validate before routing**: the operation name matches
  `[_A-Za-z][_0-9A-Za-z]*`, and the variables are legal for the operation.
- A stub must not contain accommodation logic for request shapes produced
  by the production code. If the stub needs new logic to tolerate a request,
  treat that as a defect in the request: verify it against the real API
  before accepting it.

## Serialization

Treat parse → re-serialize round-trips as unverified. Client libraries can
rewrite operation names or formatting when serializing a parsed document —
including injecting language-runtime identifiers into the name, which
servers reject. Where possible, send the original document text. If the
library serializes internally, verify the emitted operation name is legal.

## Verification

After any change to how requests are built — parsing, serialization,
transport, headers — execute one bounded live call through the normal entry
point and credential boundary: the cheapest read-only operation, `first: 1`.
Offline suites validate against fixtures only; they do not validate the
live contract.

## Debugging server 5xx errors

Servers may return 500 for malformed requests without a diagnostic.

1. Probe the minimal query; add field groups until it fails.
2. Intercept the transport and capture the exact request body the library
   sends.
3. Replay that body with curl and diff it against a known-good request.
   The difference is the defect.
