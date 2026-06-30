---
name: ruby
description: (no description)
disable-model-invocation: true
---

# Ruby Code Generation Specification for LLMs

This specification defines comprehensive requirements for generating high-quality, idiomatic Ruby code with appropriate complexity for the problem domain.

## Appropriate Complexity

### **Proportional Engineering Principle**
- **Prefer simple, readable solutions** over sophisticated frameworks for straightforward tasks
- **Abstractions should emerge from actual complexity**, not anticipated complexity
- **Use advanced patterns when they solve real problems**, not to demonstrate technical capability

#### **Avoid Over-Engineering**
- **Simple file processing**: Basic regex and File operations suffice
- **One-off utilities**: Hardcoded configuration is often appropriate
- **Straightforward data transformation**: Built-in enumerable methods are usually sufficient
- **Scripts with stable requirements**: Don't add flexibility that won't be used

### **Library Selection Guidelines**

#### **When to Use dry-rb Libraries**
- **dry-validation**: Complex business rules, multiple validation contexts, frequently changing data contracts
- **dry-configurable**: Applications with environment-specific settings, multiple configuration sources
- **dry-struct**: Complex data modeling with immutability requirements
- **dry-monads**: Multi-step operations with explicit error handling needs

## Core Architectural Requirements

### Class and Module Design
- **Single Responsibility Principle**: Each class must have one well-defined purpose
- **Descriptive Naming**: Use names that read like natural language (e.g., `DocumentProcessor`, `analyze_and_categorize`)
- **Proper Encapsulation**: Use `private` methods for internal implementation details
- **Dependency Injection**: Accept dependencies through constructor parameters or configuration blocks

### Method Structure
- **Maximum Length**: Keep methods under 10 lines when possible
- **Guard Clauses**: Use early returns for error conditions to keep main logic unindented
- **Single Purpose**: Each method should accomplish only one task
- **Meaningful Names**: Method names should clearly communicate intent and action

### **Control Flow and Readability**

#### **Simplify Logic with Guard Clauses**
Guard clauses aren't just for error handling but for any condition that simplifies the main logic:

**Example**:
```ruby
# Good: Multiple guard clauses create clear flow
def process_line(line, next_line)
  return handle_special_line(line) if special_formatting?(line)
  return handle_empty_line if line.strip.empty?

  handle_content_line(line, next_line)
end
```

#### Avoid Deep Conditional Nesting
- **Extract complex conditions**: Replace long boolean expressions with well-named predicate methods
- **Use early returns**: Reduce cognitive load by handling edge cases first
- **Prefer positive conditions**: `if valid?` reads better than `unless invalid?`

### Method Decomposition

#### Functional Decomposition
- **Single-level abstraction**: Each method should operate at one level of detail
- **Logical grouping**: Related operations should be grouped into cohesive methods
- **Progressive refinement**: Start with high-level method names, then implement details

#### Validation and Input Handling
- **Explicit validation methods**: Create dedicated `validate_input` methods rather than inline checks
- **Meaningful error messages**: Include context about what was expected vs. what was received
- **Fail fast principle**: Validate inputs at method entry points


## Code Style and Formatting Standards

### Indentation and Spacing
- **Two spaces for indentation** throughout all Ruby code (never tabs)
- **Consistent spacing** around operators, after commas, and around hash arrows
- **Line length under 80 characters** when feasible for enhanced readability

### Naming Conventions
- **snake_case** for variables and methods
- **CamelCase** for classes and modules
- **SCREAMING_SNAKE_CASE** for constants
- **Descriptive names** that are self-documenting

### Predicate Method Clarity
- **Question mark methods must return booleans**: Methods ending with `?` should never return lambdas, procs, or other objects
- **Descriptive predicate names**: Use `special_formatting?` instead of `special_line?` when the method checks formatting
- **Avoid ambiguous predicates**: If a method name could be interpreted multiple ways, choose the most specific name

### Action Method Naming
- **Use descriptive action verbs**: `finalize_current_paragraph` reads better than `flush_current_paragraph`
- **Method names should tell a story**: `process_lines` → `handle_content_line` → `finalize_current_paragraph` creates a narrative flow
- **Avoid technical jargon**: Choose domain-specific language over implementation details

### Ruby-Specific Idioms

#### String Handling
- **String interpolation** over concatenation: `"Hello #{name}"` not `"Hello " + name`
- **Heredocs with squiggly operator** for multi-line strings: ` e` for general exceptions, specific classes when appropriate
- **Don't mask debugging information** in error handling

### Defensive Programming
- **Input validation** at method boundaries **proportional to risk**
- **Nil safety** using safe navigation or explicit checks
- **Resource cleanup** in ensure blocks when necessary

## Performance and Optimization

### Efficient Ruby Patterns
- **Memoization** using `||=` operator for expensive operations
- **Lazy enumerators** for large datasets to minimize memory usage
- **Object reuse** to minimize allocations in loops
- **Appropriate data structures** for the use case

### Database and External Resources
- **Eager loading** to prevent N+1 queries in Rails applications
- **Connection pooling** for external API calls
- **Pagination** for large datasets
- **Caching strategies** for frequently accessed data

## Testing

#### **Behavior-Driven Testing**
- **Test method names should read like specifications**: `it 'preserves markdown headers when unwrapping paragraphs'`
- **Test edge cases explicitly**: Empty strings, nil values, malformed input
- **Test the happy path and error conditions**: Both successful processing and failure scenarios

#### **Integration Testing for CLI Tools**
- **Test command-line argument parsing**: Verify all option combinations work correctly
- **Test file I/O operations**: Ensure proper handling of missing files, permissions issues
- **Test output formatting**: Verify stdout/stderr usage is appropriate

### Test Integration
- **Write tests alongside code** using RSpec syntax
- **Include positive and negative test cases**
- **Mock external dependencies** appropriately
- **Test edge cases and error conditions**

## Documentation Standards

- **RDoc format** for class and method documentation
- **Meaningful comments** that explain "why" not "what"
- **Usage examples** in documentation for complex methods
- **README files** with clear setup and usage instructions

### Document Method Intent
- **Explain the "why"**: Document the business logic or algorithm reasoning
- **Include examples**: Show typical input/output for complex methods
- **Document edge cases**: Explain how the method handles unusual inputs

### Document Class Responsibility
- **Clear purpose statement**: One sentence describing what the class does
- **Usage examples**: Show typical instantiation and method calling patterns
- **Dependencies**: Document what external resources or services the class requires

### Explain Algorithms and Business Logic
Comments should explain complex algorithms, business rules, or non-obvious implementation decisions.

**Example**:
```ruby
class DocumentProcessor
  # Uses a state machine approach to handle paragraph boundaries
  # because simple line-by-line processing fails with markdown mixed content
  def process_lines(lines)
    lines.each_with_index { |line, index| process_line(line, lines[index + 1]) }
  end

  private

  # Markdown headers can appear mid-paragraph in some documents,
  # so we need to check both current line formatting and next line context
  def paragraph_break?(line, next_line = nil)
    line_ends_paragraph?(line) || next_line_starts_new_section?(next_line)
  end
end
```

### Explain Domain-Specific Context
Explain domain knowledge that might not be obvious to future maintainers.

**Example**:
```ruby
# Validates addresses against RFC 5322, but relaxes a few rules to accept
# quirks present in legacy customer data (e.g., quoted local parts, unquoted
# dots). A stricter parser would reject ~3% of our paying customers' records.
class EmailValidator
  def valid?(email)
    return false if email.nil? || email.strip.empty?

    local_part, _, domain = email.partition('@')
    return false if local_part.empty? || domain.empty?

    valid_local_part?(local_part) && valid_domain?(domain)
  end

  private

  # RFC 5322 permits quoted local parts ("john..doe"@example.com) that look
  # invalid at a glance; legacy imports rely on them, so we keep them allowed.
  def valid_local_part?(local_part)
    return true if local_part.start_with?('"') && local_part.end_with?('"')

    local_part.match?(/\A[a-zA-Z0-9._%+-]+\z/)
  end

  def valid_domain?(domain)
    domain.match?(/\A[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\z/)
  end
end
```

## Code Quality and Maintainability

### DRY Principle
- **Extract repeated code** into methods or modules
- **Use constants** for repeated values
- **Create shared modules** for common functionality
- **Avoid copy-paste programming**

### Complexity Management
- **Limit nesting** to maximum of two levels in conditionals/loops
- **Break complex methods** into smaller, focused methods
- **Use meaningful variable names** to reduce cognitive load
- **Prefer composition over inheritance** when appropriate

## Modern Ruby Features and Best Practices

### Language Features
- **Pattern matching** (Ruby 3.0+) when it improves clarity
- **Keyword arguments** for methods with multiple parameters
- **Block syntax** over method references when it improves readability
- **Struct classes** for simple data containers

### Standard Library Usage
- **FileUtils** for file operations instead of shell commands
- **Pathname** for cross-platform path manipulation
- **ENV** for environment variable access
- **JSON/YAML** libraries for data serialization

## Security Considerations

### Input Validation
- **Sanitize user inputs** to prevent injection attacks
- **Use strong parameters** in Rails applications
- **Validate data types** and ranges
- **Escape output** when rendering user content

### Authentication and Authorization
- **Secure session management**
- **Proper password handling** with bcrypt
- **CSRF protection** in web applications
- **Secure API key management**

## Framework-Specific Guidelines

### Rails Applications
- **Follow Rails conventions** for file organization and naming
- **Use Rails helpers** and built-in functionality
- **Implement proper MVC separation**
- **Use Rails generators** appropriately

### Gem Development
- **Follow semantic versioning**
- **Include proper gemspec** with dependencies
- **Provide comprehensive documentation**
- **Include executable scripts** when appropriate

## Code Analysis and Quality Assurance

### Static Analysis
- **RuboCop compliance** without violations
- **Follow Ruby Style Guide** community standards
- **Use Reek** for code smell detection
- **Implement SimpleCov** for test coverage

### Code Review Preparation
- **Structure commits logically** for easy review
- **Write descriptive commit messages**
- **Keep changes focused** and atomic
- **Include tests** with code changes

## Configuration and Environment Management

### Configuration Patterns
- **Use configuration blocks** with yielded objects
- **Environment-specific settings** in separate files
- **Secure credential management**
- **Default values** for optional configuration

### Deployment Considerations
- **Include necessary dependencies** in Gemfile
- **Environment variable documentation**
- **Database migration scripts** when applicable
- **Health check endpoints** for web applications

## Example Implementation Pattern

```ruby
# Good: Demonstrates multiple specification requirements
class DocumentProcessor
  def initialize(source_path = default_source_path)
    @source_path = source_path
    validate_source_path!
  end

  def process_documents
    documents = load_documents
    results = documents.map { |doc| analyze_document(doc) }
    save_results(results)

  rescue ProcessingError => e
    handle_processing_error(e)
  end

  private

  def validate_source_path!
    return if @source_path && Dir.exist?(@source_path)

    raise ArgumentError, "Invalid source path: #{@source_path}"
  end

  def analyze_document(document)
    return fallback_analysis(document) unless document.readable?

    perform_analysis(document)
  end

  def default_source_path
    ENV.fetch('DOCUMENT_PATH', './documents')
  end
end
```

### Anti-Patterns to Avoid

#### Don't return lambdas from predicate methods

**Example**:
```ruby
# Bad: Confusing interface
def special_line?
  ->(line) { line.start_with?('#') }
end

# Good: Clear boolean return
def special_line?(line)
  line.start_with?('#')
end
```

#### Don't duplicate code in conditionals
- **Extract shared logic**: When similar conditions appear in multiple methods, create shared helper methods
- **Use consistent patterns**: If checking for special formatting in one place, use the same logic everywhere
- **Create domain-specific predicates**: `markdown_header?`, `list_item?`, `paragraph_ending?`


## Quality Checklist

Before considering Ruby code complete, verify:

- [ ] Complexity is proportional to problem domain
- [ ] All public methods have clear, descriptive names
- [ ] Private methods are used appropriately for internal logic
- [ ] Error handling includes meaningful messages and fallback strategies
- [ ] Code follows DRY principle without over-abstraction
- [ ] Tests cover both happy path and edge cases
- [ ] Documentation explains complex logic and usage
- [ ] RuboCop passes without violations
- [ ] Method length stays under 10 lines where possible
- [ ] Nesting depth remains under 2 levels
- [ ] String interpolation is used instead of concatenation
- [ ] Advanced libraries are used only when they solve real problems
- [ ] Method names read like natural English sentences
- [ ] Predicate methods (ending with `?`) return only boolean values
- [ ] Complex conditions are extracted into well-named predicate methods
- [ ] Guard clauses are used to simplify main logic flow
- [ ] Input validation occurs at method entry points with meaningful error messages
- [ ] No code duplication exists between similar conditional checks
- [ ] Each method operates at a single level of abstraction
- [ ] Class and method documentation explains intent, not just implementation
- [ ] Tests cover both typical usage and edge cases
- [ ] CLI tools properly handle argument parsing and file I/O errors
