# Lessons Learned: Building a Modern Parser for Legacy FEM Software

**A Software Engineering Journey with AbaqusReader.jl**

*By Jukka Aho*

---

## The Story

### The Problem I Faced

I've been working in computational engineering for years, using ABAQUS as the primary FEM tool. It's powerful, mature, and has decades of development behind it. But as a software engineer who cares about code quality, I kept running into the same frustration:

**ABAQUS's element type system is fundamentally broken from a software design perspective.**

When I needed to read ABAQUS input files in Julia for the JuliaFEM project, I had a choice:

1. Replicate ABAQUS's design (easy path - just map their types)
2. Fix it properly (hard path - rethink the architecture)

I chose the hard path. This is why, and what I learned.

---

## The Wake-Up Call

### Discovering the Exponential Explosion

ABAQUS has **100+ element types**. When I started cataloging them, I noticed a pattern:

```text
CPS3  = 3-node triangle + Plane Stress
CPE3  = 3-node triangle + Plane Strain  
CAX3  = 3-node triangle + Axisymmetric
C3D3  = 3-node triangle + 3D

CPS4  = 4-node quad + Plane Stress
CPE4  = 4-node quad + Plane Strain
CAX4  = 4-node quad + Axisymmetric
C3D4  = 4-node quad + 3D (tetrahedron)
...
```

**Same topology, different physics.** But each is a completely separate type.

The math hit me: `Types = Topologies × Physics × Integration × Features`

With 10 topologies, 4 physics models, 3 integration schemes, and 2 features, you get **240 element types**. And ABAQUS has even more dimensions than that.

**This is O(exponential) complexity.** As a software engineer, alarm bells went off.

---

## The SOLID Revelation

### When Theory Meets Practice

I teach software engineering. I know SOLID principles. But seeing them *all violated in one design* was eye-opening:

- **S**ingle Responsibility: Elements handle topology + physics + integration + features
- **O**pen/Closed: Can't add new physics without modifying everything
- **L**iskov Substitution: CPS3 and CPE3 both triangles, but not substitutable
- **I**nterface Segregation: Need topology? Get physics too (unwanted coupling)
- **D**ependency Inversion: Everything depends on concrete type name strings

**Every. Single. One. Violated.**

This wasn't just "suboptimal design" - this was a textbook example of *what not to do*.

---

## The Decision: Don't Replicate Mistakes

### Why I Didn't Just Map ABAQUS Types

The easy path would be:

```julia
# Just map their types directly
struct CPS3 end
struct CPE3 end
struct CAX3 end
# ... 100+ more structs
```

But this would:

1. **Import the architectural problems** into Julia
2. **Couple Julia code to ABAQUS's mistakes**
3. **Prevent proper abstraction** over topology
4. **Miss the opportunity** to do it right

As proud software engineers building modern FEM tools, we can do better.

---

## The Solution: Separation of Concerns

### What AbaqusReader.jl Actually Does

```julia
mesh = abaqus_read_mesh("model.inp")

# Returns clean topology
mesh["element_types"][1] = :Tri3              # Topological type only
mesh["element_codes"][1] = :CPS3              # Original ABAQUS name preserved

# Users compose their own physics
elem = Tri3(mesh["elements"][1])              # Clean topology
physics = infer_physics(mesh["element_codes"][1])  # User's choice
K = stiffness(elem, physics)                  # Proper composition
```

**Key principles:**

- **Topology separated from physics** - orthogonal concerns stay separate
- **Original names preserved** - full traceability to ABAQUS
- **Linear complexity** - 15 topological types instead of 100+
- **Extensible** - add physics without touching topology code
- **Composable** - users build behavior from orthogonal pieces

---

## What I Learned

### Lesson 1: Legacy ≠ Best Practice

**Just because software is old, mature, and commercially successful doesn't mean its architecture is good.**

ABAQUS dates from the 1970s, when:

- FORTRAN was the only option
- Procedural programming was standard
- Type systems were primitive
- Templates, traits, and multiple dispatch didn't exist

The design made sense *then*. But frozen in that paradigm for 50 years, it became a warning example.

**Key insight**: Respect the domain expertise (FEM algorithms), reject the architectural mistakes.

### Lesson 2: Separation of Concerns is Not Academic

I used to think "separation of concerns" was abstract theory. Then I hit exponential type proliferation.

**Orthogonal concerns that aren't separated lead to exponential complexity.**

Topology and physics are mathematically independent:

- Any topology works with any physics
- Changing topology shouldn't affect physics code
- Changing physics shouldn't affect topology code

When ABAQUS coupled them, they created 100+ types. When we separated them, we got 15.

**Key insight**: Orthogonality in the problem domain should be orthogonality in the code.

### Lesson 3: Modern Language Features Exist For This

Julia's multiple dispatch is *designed* for this problem:

```julia
# Define concerns separately
struct Tri3 <: Element end
struct PlaneStress <: Physics end
struct FullIntegration <: Integration end

# Compose at call site
function stiffness(e::Element, p::Physics, i::Integration)
    # Specialized automatically via multiple dispatch
end

# Extensibility: add new physics
struct Hyperelastic <: Physics end

# Works automatically with all existing topologies!
```

C++ templates, Rust traits, and Haskell type classes solve the same problem.

**Modern languages have features specifically designed to prevent exponential type proliferation.**

ABAQUS is stuck in 1970s FORTRAN procedural thinking, where the only abstraction mechanism was "different subroutine = different behavior".

**Key insight**: Use your language's type system properly. It exists for exactly this reason.

### Lesson 4: Compatibility Traps Are Real

ABAQUS *knows* their element design is problematic. But they can't fix it because:

- Millions of existing input files depend on exact element type names
- Commercial users depend on backward compatibility
- Refactoring would break *everything*

This is **technical debt** that became **unpayable**.

The lesson: **Design for extensibility from day one.** Once you ship exponential complexity, you're stuck with it forever.

**Key insight**: Poor architectural decisions compound over decades. Fix them early or live with them forever.

### Lesson 5: Sometimes You Should Say "No"

The hardest decision was: **Should AbaqusReader.jl replicate ABAQUS's type system?**

Users might expect it. It would be "compatible" with ABAQUS thinking. Some might complain that we "don't follow the standard."

But here's the thing: **We're not obligated to replicate bad design.**

We support the *format* (interoperability). We preserve the *names* (traceability). But we don't replicate the *architecture* (mistakes).

**As software engineers, it's our responsibility to insulate users from bad design decisions made 50 years ago.**

**Key insight**: Interoperability doesn't mean replicating mistakes. You can support a format without importing its flaws.

---

## The Bigger Picture

### Why This Matters Beyond ABAQUS

This isn't just about FEM or ABAQUS. The lessons apply everywhere:

#### In Scientific Computing

Many scientific codes date from the 1970s-1990s. They have deep domain expertise but dated software architecture. When building modern tools that interface with them:

- **Extract the science** (algorithms, methods)
- **Reject the architecture** (if it violates modern principles)
- **Provide clean interfaces** for new code

#### In Data Engineering

Legacy data formats often have structural problems. When building parsers:

- **Parse faithfully** (preserve all information)
- **Transform to clean structures** (separation of concerns)
- **Don't import the mess** into your codebase

#### In API Design

When building libraries, think about extensibility:

- **Will adding dimension X require N new types?** → You're creating exponential complexity
- **Are orthogonal concerns coupled?** → Separate them now, or pay later
- **Can users extend without modifying your code?** → If not, refactor

---

## For Educators

### Teaching SOLID with Real Examples

ABAQUS is a *perfect teaching tool* for software engineering because:

1. **It's real** - Not a toy example, but a major commercial product
2. **It violates all SOLID principles** - Clear, concrete violations
3. **The consequences are visible** - 100+ types, code duplication, unmaintainability
4. **The fix is obvious** - Separation of concerns via modern type systems
5. **The lesson generalizes** - Same pattern appears in many domains

**Classroom exercise I now use:**

*"You're designing a FEM library. You need 10 topologies, 5 physics models, 3 integration schemes, 2 features. Do you create 300 element types or 20 composable types? Discuss the SOLID implications."*

Students immediately see why separation of concerns matters when faced with exponential vs. linear complexity.

---

## Conclusion: Pride in Craft

### What AbaqusReader.jl Represents

This package is more than a parser. It's a statement about software engineering:

1. **We respect domain expertise** - ABAQUS's FEM algorithms are excellent
2. **We reject architectural mistakes** - Their type system is not
3. **We design for the future** - Linear complexity, extensibility, composition
4. **We're proud of our craft** - Software engineering principles matter

### The Meta-Lesson

**Sometimes the most important contribution isn't the code - it's the decision of what NOT to replicate.**

By refusing to import ABAQUS's exponential complexity into Julia, AbaqusReader.jl provides:

- A **clean foundation** for Julia FEM codes
- An **example** of proper separation of concerns
- A **teaching tool** for software engineering principles
- A **reminder** that legacy doesn't mean best practice

---

## References and Further Reading

### On SOLID Principles

- Martin, R.C. (2000). *Design Principles and Design Patterns*
- Martin, R.C. (2017). *Clean Architecture*

### On Separation of Concerns

- Dijkstra, E.W. (1982). "On the role of scientific thought"
- Parnas, D.L. (1972). "On the criteria to be used in decomposing systems into modules"

### On Type System Design

- Pierce, B.C. (2002). *Types and Programming Languages*
- Bezanson, J., et al. (2017). "Julia: A fresh approach to numerical computing"

### On Technical Debt

- Cunningham, W. (1992). "The WyCash portfolio management system"
- Fowler, M. (2019). "Technical Debt" (martinfowler.com)

---

## Acknowledgments

This work grew from the JuliaFEM project and discussions with the Julia community about proper abstraction and type design. Thanks to everyone who challenged me to articulate *why* ABAQUS's design felt wrong - that pressure led to this clarity.

Special thanks to the Julia core team for creating a language with the right abstractions to solve this problem elegantly.

---

*Want to discuss these ideas? Open an issue on [GitHub](https://github.com/ahojukka5/AbaqusReader.jl) or find me in the Julia community.*
