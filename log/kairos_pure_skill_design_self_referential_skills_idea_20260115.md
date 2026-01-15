# Kairos Pure Skill Design — Self-Referential skills.rb Model

## 0. Purpose of This Document

This document proposes a **pure skill design** for a self-referential `skills.rb` model, intended to be passed to AI coding agents (e.g. Cursor, Claude Code, Antigravity) as **design constraints and implementation guidance**.

The goal is to define **skills as named, side-effect-contained contexts**, analogous to *pure functions* in functional programming, while still allowing **controlled evolution** via explicit, rule-bound mechanisms.

This is **not** a prompt, policy text, or runtime configuration. It is a **constitutional design** for an agentic system (Kairos) implemented on a Ruby-based MCP Server.

---

## 1. Design Principles (High-Level)

### P1. Skills Are Pure by Default

- A skill must not modify global state implicitly
- A skill may only read explicitly declared inputs
- A skill may only modify explicitly declared internal state

> Analogy: **pure functions with explicit State / IO contexts**

---

### P2. Side Effects Are Named and Scoped

- Any mutation, execution, or rule evolution must occur inside a *named context*
- Unnamed or implicit side effects are forbidden

> Analogy: **IO / State monads with explicit labels**

---

### P3. Self-Reference Is Structural, Not Magical

- Skills may reference their own definition and history
- Skills may not arbitrarily rewrite themselves
- All self-modification must follow pre-declared evolution rules

---

### P4. Evolution Is Constrained (Minimum-Nomic)

- Rules can evolve
- The *rules governing evolution* are strictly limited
- Core invariants are immutable

---

## 2. Conceptual Model

```
Skill
 ├─ Identity (name, version)
 ├─ Inputs (explicit context)
 ├─ Guarantees (invariants)
 ├─ Behavior (pure transformation)
 ├─ Effects (named side-effect contexts)
 ├─ Evolution Rules (how this skill may change)
 └─ History (append-only)
```

A **Skill is both rule and subject**, but never an unconstrained editor of itself.

---

## 3. Minimal Pure Skill DSL (Core)

```ruby
skill :pipeline_generation do
  version "1.0"

  # Explicit inputs
  inputs :genomic_context, :parameters

  # Invariants that must always hold
  guarantees do
    reproducible
    explainable
  end

  # Pure behavior: no side effects allowed here
  behavior do |input|
    Pipeline.plan(input)
  end
end
```

### Semantics

- `behavior` must be referentially transparent
- No file IO, network, or mutation allowed
- Violations are rejected at parse or execution time

---

## 4. Named Side-Effect Contexts

Side effects are allowed **only** inside explicitly declared contexts.

```ruby
skill :pipeline_execution do
  inputs :pipeline_plan

  effect :execution do
    requires :human_approval
    records :audit_trail
  end

  behavior do |plan|
    plan
  end

  effect :execution do |plan|
    Executor.run(plan)
  end
end
```

### Semantics

- Effects are separate from behavior
- Effects must declare:
  - Preconditions
  - Recording requirements
- Effects are composable and auditable

---

## 5. Self-Referential Introspection (Read-Only)

```ruby
skill :self_inspection do
  inputs :none

  behavior do
    Kairos.skills.map do |skill|
      {
        name: skill.name,
        version: skill.version,
        invariants: skill.guarantees,
        history: skill.history.summary
      }
    end
  end
end
```

### Constraints

- Introspection is read-only
- No mutation permitted
- Enables explainability and auditability

---

## 6. Controlled Self-Evolution

Self-modification is **proposal-based**, never direct.

```ruby
skill :pipeline_generation do
  evolve do
    allow :parameter_defaults
    deny :guarantees

    when :high_failure_rate do |current|
      propose change(:parameter_defaults) do |defaults|
        defaults.merge(timeout: 20)
      end
    end
  end
end
```

### Semantics

- Skills may *propose* changes
- MCP Server validates:
  - Scope
  - Invariants
  - Conflicts
- Application requires explicit approval

---

## 7. Immutability & History

- Skill definitions are immutable snapshots
- Evolution creates a new version
- History is append-only

```text
pipeline_generation v1.0
  → v1.1 (parameter_defaults adjusted)
```

This enables:
- Diff-based review
- Rollback
- Provenance

---

## 8. What Is Explicitly Forbidden

- Global state mutation
- Unnamed side effects
- Self-modification without declared evolution rules
- Deletion of history
- Modification of invariants

---

## 9. Why This Cannot Be Reproduced Cleanly with skills.md

| Aspect | skills.md + operator | skills.rb (this design) |
|------|----------------------|--------------------------|
| Side effects | Implicit | Named & scoped |
| Evolution rules | External logic | Co-located with rule |
| Self-reference | Manual | Structural |
| Auditability | Fragmented | Native |
| Cognitive load | High | Low |

The key difference is **where correctness lives**:

- skills.md: in human discipline
- skills.rb: in language structure

---

## 10. Positioning

This design treats skills as:

- **Typed rule contexts**
- **Pure-by-default transformations**
- **Auditable, evolvable subjects**

It is conceptually aligned with:

- Functional programming (purity, explicit effects)
- ActiveRecord-style declarative magic (structure → behavior)
- Constitutional systems (rules + amendment procedures)

---

## 11. Instruction to AI Coding Agents

When implementing or modifying code under this design:

- Do NOT optimize for convenience
- Do NOT bypass named effect contexts
- Treat skills as immutable specifications
- Propose changes, never apply silently

---

## 12. Status

This document defines a **conceptual reference architecture**.

It is intended for:
- Cursor-guided implementation
- MCP Server design
- Kairos PoC development

Not for:
- Direct production deployment
- Performance optimization

---

(End of document)

