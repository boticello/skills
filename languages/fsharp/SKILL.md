---
name: fsharp
description: (no description)
disable-model-invocation: true
---

# F# LLM-Assisted Development Guide

## Overview

This guide establishes guardrails for LLM-assisted F# development with emphasis on functional programming, type safety, and robust text processing. F# provides a powerful type system, excellent .NET integration, and strong safety guarantees through immutability and pattern matching.

## Core Principles

### 1. Type-Driven Development
- Leverage F#'s powerful type inference and type system
- Use algebraic data types (discriminated unions) for domain modeling
- Implement exhaustive pattern matching
- Utilize single-case unions for type-safe primitives
- Apply units of measure for domain-specific types

### 2. Functional Programming Standards
- Prefer immutability by default
- Use pure functions wherever possible
- Leverage function composition and piping
- Avoid mutable state unless performance-critical
- Implement railway-oriented programming for error handling

### 3. Test-Driven Development
- Write tests using Expecto or xUnit before implementation
- Use FsCheck for property-based testing
- Ensure comprehensive test coverage
- Test edge cases with exhaustive pattern matching

## LLM Interaction Guardrails

### Input Validation Prompts

Always begin LLM interactions with this context:

```
You are helping with F# development. Please ensure:

1. All code follows F# style conventions
2. Type safety with explicit type annotations for public APIs
3. Immutability by default - use mutable only when necessary
4. Pattern matching is exhaustive with no wildcard catches
5. Error handling uses Result types or Option types, not exceptions
6. Railway-oriented programming for composable error handling
7. Code includes comprehensive tests using Expecto or xUnit
8. Performance considerations documented with complexity analysis
9. Pure functions preferred over side effects
10. Domain modeling with discriminated unions and records

Please provide complete, working examples with error handling.
```

### Code Review Checklist

Before accepting LLM-generated code:

- [ ] **Type Safety**: All public functions have explicit type signatures
- [ ] **Immutability**: Mutable state justified and documented
- [ ] **Pattern Matching**: All cases covered, no catch-all wildcards
- [ ] **Error Handling**: Result/Option types used instead of exceptions
- [ ] **Purity**: Side effects isolated to module boundaries
- [ ] **Testing**: Comprehensive tests with property-based testing
- [ ] **Documentation**: XML doc comments for public APIs
- [ ] **Performance**: Tail recursion used where appropriate

### Forbidden Patterns

Never accept LLM suggestions containing:

```fsharp
// ❌ Untyped function signatures
let process data =
    // Missing type information
    data

// ❌ Non-exhaustive pattern matching
let processValue x =
    match x with
    | Some v -> v
    // Missing None case

// ❌ Exception-based error handling in business logic
let parseNumber str =
    int str  // Throws exception

// ❌ Unnecessary mutable state
let mutable globalData = Map.empty

// ❌ Wildcard pattern matching
let handleCase x =
    match x with
    | SpecificCase -> "ok"
    | _ -> "unknown"  // Hides unhandled cases
```

### Required Patterns

Always require LLM to include:

```fsharp
// ✅ Explicit typing for public APIs
/// Splits input text into words
/// Returns list of non-empty words
let processText (input: string) : string list =
    input.Split([|' '|], StringSplitOptions.RemoveEmptyEntries)
    |> Array.toList

// ✅ Option types for potentially missing values
/// Safe division returning None for division by zero
let safeDivide (a: float) (b: float) : float option =
    if b = 0.0 then None
    else Some (a / b)

// ✅ Result types for error handling
type ParseError =
    | EmptyInput
    | InvalidFormat of string

type ParseResult<'T> = Result<'T, ParseError>

let parseNumber (input: string) : ParseResult<int> =
    if String.IsNullOrWhiteSpace(input) then
        Error EmptyInput
    else
        match Int32.TryParse(input) with
        | true, value -> Ok value
        | false, _ -> Error (InvalidFormat input)

// ✅ Domain modeling with discriminated unions
type UserRole =
    | Admin
    | User
    | Guest

type EmailAddress = EmailAddress of string
type UserId = UserId of int

// ✅ Comprehensive tests with Expecto
module Tests =
    open Expecto

    [<Tests>]
    let tests =
        testList "TextProcessor" [
            test "splits text correctly" {
                let result = processText "hello world"
                Expect.equal result ["hello"; "world"] "Should split on spaces"
            }
            
            test "handles empty input" {
                let result = processText ""
                Expect.isEmpty result "Should return empty list"
            }
            
            test "removes extra spaces" {
                let result = processText "hello  world"
                Expect.equal result ["hello"; "world"] "Should handle multiple spaces"
            }
        ]

// ✅ Property-based testing with FsCheck
module PropertyTests =
    open FsCheck
    open FsCheck.Xunit

    [<Property>]
    let ``processText never returns empty strings`` (input: string) =
        let result = processText input
        result |> List.forall (fun s -> s.Length > 0)
```

## Project Structure Template

```
src/
  Program.fs            # Entry point
  Library/
    TextProcessor.fs    # Core logic modules
    Types.fs           # Domain types
    Result.fs          # Result type helpers
tests/
  TextProcessor.Tests.fs
  Property.Tests.fs
paket.dependencies     # Dependencies
mise.toml             # Tool configuration
```

## Development Workflow

### 1. Project Initialization
```bash
# Generate new F# project
mise run new-project [project-name]

# Install dependencies
mise run restore

# Run initial tests
mise run test
```

### 2. TDD Cycle
```bash
# Write failing test first
mise run test-watch

# Implement feature with LLM assistance
# Follow guardrails in this guide

# Verify all tests pass
mise run test

# Check code quality
mise run lint
```

### 3. Quality Gates

Before committing:
```bash
# Format code
mise run format

# Type checking
mise run build

# Run full test suite
mise run test

# Property-based tests
mise run test-property

# Generate documentation
mise run docs
```

## LLM Prompt Templates

### Feature Implementation
```
Implement a [feature description] in F# that:

1. Accepts [input types] as parameters
2. Returns [output type] wrapped in Result or Option
3. Handles [error conditions] using discriminated unions
4. Follows F# functional programming conventions
5. Uses immutable data structures
6. Includes comprehensive tests with Expecto
7. Includes property-based tests with FsCheck
8. Has O([complexity]) performance

Please provide the implementation with:
- Explicit type signatures
- Result/Option types for error handling
- Exhaustive pattern matching
- Pure functions where possible
- Complete test coverage including properties
- XML documentation comments

Example usage: [provide example]
```

### Code Review
```
Review this F# code for:

1. Type safety issues
2. Non-exhaustive pattern matches
3. Unnecessary mutable state
4. Exception-based error handling (use Result/Option)
5. Missing edge cases
6. Test coverage gaps
7. Documentation issues
8. Opportunities for function composition

[paste code here]

Provide specific fixes with explanations following F# best practices.
```

### Debugging
```
Debug this F# compilation error:

Error: [paste error]
Code: [paste code]

Please:
1. Explain the root cause
2. Provide the corrected code with proper types
3. Explain how to prevent similar issues
4. Suggest any missing tests
5. Identify opportunities for better type modeling
```

## Performance Guidelines

### Text Processing Optimizations
```fsharp
// Use StringBuilder for string construction
open System.Text

let buildString (parts: string list) : string =
    let sb = StringBuilder()
    parts |> List.iter (sb.Append >> ignore)
    sb.ToString()

// Use sequences for lazy evaluation
let processLargeFile (filePath: string) : seq<string> =
    System.IO.File.ReadLines(filePath)
    |> Seq.map (fun line -> line.Trim())
    |> Seq.filter (String.IsNullOrWhiteSpace >> not)

// Tail-recursive functions for stack safety
let rec sumList (acc: int) (list: int list) : int =
    match list with
    | [] -> acc
    | head :: tail -> sumList (acc + head) tail
```

### Functional Performance Patterns
```fsharp
// Use active patterns for efficient parsing
let (|Integer|_|) (str: string) =
    match Int32.TryParse(str) with
    | true, value -> Some value
    | false, _ -> None

let parseInput input =
    match input with
    | Integer n -> Ok n
    | _ -> Error (InvalidFormat input)
```

## Railway-Oriented Programming

### Composable Error Handling
```fsharp
module Result =
    let bind f result =
        match result with
        | Ok value -> f value
        | Error e -> Error e
    
    let map f result =
        match result with
        | Ok value -> Ok (f value)
        | Error e -> Error e

// Composition example
type ValidationError =
    | EmptyInput
    | TooShort of int
    | InvalidChars of char list

let validateNotEmpty (input: string) : Result<string, ValidationError> =
    if String.IsNullOrWhiteSpace(input) then Error EmptyInput
    else Ok input

let validateLength (minLen: int) (input: string) : Result<string, ValidationError> =
    if input.Length < minLen then Error (TooShort input.Length)
    else Ok input

let processInput (input: string) : Result<string, ValidationError> =
    input
    |> validateNotEmpty
    |> Result.bind (validateLength 3)
    |> Result.map (fun s -> s.Trim())
```

## Security Considerations

### Type-Safe Input Validation
```fsharp
// Single-case unions prevent primitive obsession
type EmailAddress = private EmailAddress of string
type PhoneNumber = private PhoneNumber of string

module EmailAddress =
    let create (str: string) : Result<EmailAddress, string> =
        if str.Contains("@") && str.Contains(".") then
            Ok (EmailAddress str)
        else
            Error "Invalid email format"
    
    let value (EmailAddress email) = email

// Usage prevents invalid data at compile time
let sendEmail (to: EmailAddress) (message: string) : unit =
    printfn "Sending to: %s" (EmailAddress.value to)

// This won't compile - type safety enforced
// sendEmail "not-validated@example.com" "test"
```

### Constrained Types with Units of Measure
```fsharp
[<Measure>] type ms
[<Measure>] type s

let toSeconds (time: float<ms>) : float<s> =
    time / 1000.0<ms/s>

// Prevents unit confusion at compile time
let timeout = 5000.0<ms>
let timeoutSeconds = toSeconds timeout
```

## Documentation Standards

### XML Documentation
```fsharp
/// Text processing utilities for handling user input.
///
/// This module provides safe, efficient text processing functions
/// with comprehensive error handling using Result types.
module TextProcessor =
    
    /// Cleans user input by removing dangerous characters.
    ///
    /// <param name="input">The input string to clean</param>
    /// <returns>Result containing cleaned string or error</returns>
    /// <example>
    /// <code>
    /// let result = cleanText "&lt;script&gt;alert('xss')&lt;/script&gt;"
    /// // Returns: Ok "scriptalert('xss')/script"
    /// </code>
    /// </example>
    let cleanText (input: string) : Result<string, string> =
        if String.IsNullOrWhiteSpace(input) then
            Error "Input cannot be empty"
        else
            input
            |> String.filter (fun c -> not (List.contains c ['<'; '>'; '&']))
            |> Ok
```

## Active Patterns for Type-Safe Parsing

```fsharp
// Complete active pattern
let (|ValidEmail|InvalidEmail|) (input: string) =
    if input.Contains("@") && input.Contains(".") then
        ValidEmail input
    else
        InvalidEmail

// Partial active pattern  
let (|Integer|_|) (str: string) =
    match Int32.TryParse(str) with
    | true, n -> Some n
    | _ -> None

let (|Float|_|) (str: string) =
    match Double.TryParse(str) with
    | true, f -> Some f
    | _ -> None

// Multi-case active pattern
let (|Even|Odd|) n =
    if n % 2 = 0 then Even else Odd

// Usage
let processEmail email =
    match email with
    | ValidEmail addr -> Ok addr
    | InvalidEmail -> Error "Invalid email"

let parseNumber str =
    match str with
    | Integer n -> Ok (float n)
    | Float f -> Ok f
    | _ -> Error "Not a number"
```

## Continuous Integration

Ensure mise tasks cover:
- Compilation checks
- Test execution (unit and property-based)
- Code formatting (Fantomas)
- Documentation generation
- Static analysis (FSharpLint)
- Performance benchmarks
- Coverage reports

This guide provides comprehensive guardrails for safe, effective LLM-assisted F# development with strong type safety, functional programming principles, and robust error handling.
