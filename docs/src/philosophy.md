# Philosophy: ABAQUS as a Warning Example

![ABAQUS Design Philosophy - Separation of Concerns](assets/hero-image.webp)

## Our Position

**ABAQUS element design is a cautionary tale in software engineering.**

From a computer science perspective, ABAQUS demonstrates what happens when you violate separation of concerns and mix orthogonal dimensions into a single type hierarchy. We're software engineers, and we recognize bad design when we see it - even in commercial products.

**We don't dance to ABAQUS's whistle.** We support their format (interoperability) but don't replicate their architectural mistakes (exponential hell).

---

## The Problem: Exponential Complexity

ABAQUS creates separate element types for every combination of:

- **Topology** (3 nodes, 4 nodes, 8 nodes...)
- **Physics** (plane stress, plane strain, axisymmetric, 3D...)
- **Integration** (full, reduced, selective...)
- **Features** (hybrid, incompatible modes, temperature...)

### Example: The Triangle Family

```
CPS3  = 3 nodes + Plane Stress + Standard
CPE3  = 3 nodes + Plane Strain + Standard
CAX3  = 3 nodes + Axisymmetric + Standard
C3D3  = 3 nodes + 3D + Standard
...
```

Same 3-node triangle topology, different physics. But ABAQUS treats them as completely different element types.

**Result**: 100+ element types with massive code duplication.

### The Growth Pattern

```
Types = Topologies × Physics × Integration × Features

Example:
  10 topologies × 4 physics × 3 integration × 2 features = 240 types

Adding one topology → Create 24 new variants (4×3×2)
Adding one physics → Create 60 new variants (10×3×2)
```

This is **O(exponential)** complexity. Unmaintainable. Unextensible.

---

## Why This Is Wrong: Computer Science Perspective

### 1. Violates Separation of Concerns

Topology and physics are **orthogonal** - they vary independently:

- You can have any topology with any physics formulation
- Changing topology shouldn't require changing physics code
- Changing physics shouldn't require changing topology code

**ABAQUS couples them in the element type name.** This is the fundamental mistake.

### 2. Violates DRY (Don't Repeat Yourself)

```fortran
! FORTRAN-style code (1970s paradigm)
SUBROUTINE CPS3_STIFFNESS(...)
  ! Shape functions for 3-node triangle
  ! Plane stress formulation
  ! Integration scheme
END

SUBROUTINE CPE3_STIFFNESS(...)
  ! Shape functions for 3-node triangle  (DUPLICATED!)
  ! Plane strain formulation
  ! Integration scheme                   (DUPLICATED!)
END

SUBROUTINE CAX3_STIFFNESS(...)
  ! Shape functions for 3-node triangle  (DUPLICATED!)
  ! Axisymmetric formulation
  ! Integration scheme                   (DUPLICATED!)
END
```

Same shape functions, same integration - duplicated across every physics variant.

### 3. Violates Open/Closed Principle

Software should be **open for extension, closed for modification**.

**In ABAQUS**: Want to add a new physics formulation?
- Must create N new element types (one per topology)
- Must modify the element type registry
- Must duplicate shape functions and integration code
- Must update documentation, tests, user manuals

**This is not extensible.**

### 4. Not Composable

Modern software builds complex behavior by composing simple pieces:

```
stiffness = topology ∘ physics ∘ integration
```

ABAQUS has monolithic types instead. No composition, no reuse.

---

## The Modern Solution: Separation via Type Systems

### What We Should Do (Julia Multiple Dispatch)

```julia
# Define concerns independently
struct Tri3 
    nodes::Vector{Int}  # Topology only - geometry
end

struct Quad4
    nodes::Vector{Int}
end

# Physics formulations - separate types
struct PlaneStress end
struct PlaneStrain end
struct Axisymmetric end

# Integration schemes - separate types
struct FullIntegration end
struct ReducedIntegration end

# Compose via multiple dispatch
function stiffness(elem::Tri3, phys::PlaneStress, integ::FullIntegration)
    # Only this specific combination
end

function stiffness(elem::Tri3, phys::PlaneStrain, integ::FullIntegration)
    # Different physics, same topology - reuses Tri3 shape functions
end

# Extensibility: Add new physics without touching topology
struct NonlinearElastic end

function stiffness(elem::Tri3, phys::NonlinearElastic, integ::FullIntegration)
    # New physics, existing topology - zero modifications to Tri3 code
end
```

**Complexity**: O(T + P + I) types instead of O(T × P × I)

**Result**: 19 types instead of 240

### C++ Templates

```cpp
// Topology
template<int N>
class Triangle { 
    std::array<int, N> nodes; 
};

// Compose at compile time
template<typename Physics, typename Integration>
Matrix stiffness(Triangle<3>& elem, Physics p, Integration i) {
    // Specialized per combination
    // Zero runtime overhead
}

// Extensibility: Add new physics
struct NewPhysics { };

// Automatically works with all topologies!
```

### Rust Traits

```rust
// Separate traits for each concern
trait Element {
    fn nodes(&self) -> &[usize];
}

trait Formulation {
    fn stress_state(&self) -> StressState;
}

trait Quadrature {
    fn points(&self) -> Vec<Point>;
}

// Compose orthogonally
fn solve<E: Element, F: Formulation, Q: Quadrature>(
    elem: &E, form: &F, quad: &Q
) {
    // Type system ensures valid combinations
}
```

---

## Why ABAQUS Is This Way: Historical Context

### 1970s FORTRAN Legacy

ABAQUS originated in the 1970s when:
- FORTRAN was the dominant language
- Procedural programming was the only paradigm
- Subroutines were the abstraction mechanism
- Templates, traits, and multiple dispatch didn't exist

**Design consequence**: Each element type = one subroutine. Different behavior = different subroutine.

### Technical Debt Accumulation

After 40+ years:
- Cannot break existing input files (millions of them exist)
- Backward compatibility is absolute requirement
- Refactoring is commercially impossible
- "Add feature" → "add element type" became the pattern

**Result**: Architecture frozen in 1970s paradigm despite modern alternatives.

### Why Dassault Didn't Fix It

1. **Legacy inertia** - Too much existing code to refactor
2. **Backward compatibility trap** - Must support ancient input files
3. **Feature-driven development** - Add features by adding types, not abstraction
4. **No architectural vision** - No incentive to refactor what "works"

**ABAQUS is a powerful product with terrible architecture.** A warning example for software engineering education.

---

## AbaqusReader's Solution

### What We Do

**We extract topology separately from physics:**

```julia
mesh = abaqus_read_mesh("model.inp")

# Returns:
mesh["elements"][1] = [1, 2, 3]              # Connectivity
mesh["element_types"][1] = :Tri3             # Topological type  
mesh["element_codes"][1] = :CPS3             # Original ABAQUS name
```

**Users compose their own physics:**

```julia
# User's FEM code
elem = Tri3(mesh["elements"][1])
code = mesh["element_codes"][1]  # :CPS3 tells us it was plane stress

physics = if code == :CPS3
    PlaneStress()
elseif code == :CPE3
    PlaneStrain()
else
    error("Unknown physics for $code")
end

K = stiffness(elem, physics)  # Clean composition
```

### Why This Is Correct

1. **Separation of concerns** - Topology independent of physics
2. **Linear complexity** - 15 topological types vs. ABAQUS's 100+
3. **Extensible** - Add physics without touching topology code
4. **Composable** - Users build behavior from orthogonal pieces
5. **Modern** - Uses Julia's type system properly

### What We Preserve

- ✓ Original ABAQUS element names in `element_codes` (full traceability)
- ✓ Node connectivity and numbering
- ✓ Element sets and surfaces
- ✓ Material names (but not properties - that's physics)

### What We Don't Replicate

- ✗ ABAQUS's element type proliferation
- ✗ Coupling topology with physics
- ✗ Exponential complexity
- ✗ Code duplication

**We're software engineers. We insulate Julia users from ABAQUS's architectural problems.**

---

## For Educators: Using ABAQUS as a Teaching Example

### What This Demonstrates

1. **Separation of Concerns** - Orthogonal dimensions should be separate types
2. **Open/Closed Principle** - Extend without modifying existing code
3. **DRY Principle** - Single authoritative representation of knowledge
4. **Complexity Analysis** - Exponential vs. linear growth patterns
5. **Technical Debt** - How poor decisions compound over decades
6. **Type System Design** - Using language features vs. nomenclature hacks

### Questions to Ask During Design

1. Are these concerns **orthogonal** (vary independently)?
   - If YES → Separate types that compose
   - If NO → Single abstraction may be OK

2. Will adding dimension X require variants of all Y?
   - If YES → You're creating exponential complexity
   - If NO → Good, concerns are separated

3. Am I duplicating logic across types?
   - If YES → Abstract the common parts
   - If NO → Good, following DRY

4. Can I extend without modifying existing code?
   - If YES → Following Open/Closed Principle
   - If NO → Refactor for extensibility

### The Lessons

| **❌ Don't Do This (ABAQUS)** | **✅ Do This (Modern)** |
|-------------------------------|------------------------|
| Mix orthogonal concerns in type names | Separate concerns into independent types |
| Use nomenclature instead of type system | Use language features (templates/traits/dispatch) |
| Duplicate code across variants | Compose at call site |
| Design for immediate needs only | Design for exponential growth from start |
| Let compatibility prevent improvement | Refactor early before debt compounds |

---

## Summary

| Aspect | ABAQUS (Wrong) | Modern Approach (Right) |
|--------|----------------|------------------------|
| **Concerns** | Mixed in type names | Separated into types |
| **Complexity** | O(exponential) | O(linear) |
| **Extensibility** | Modify + duplicate | Extend via composition |
| **Code Reuse** | Heavy duplication | Single implementation |
| **Paradigm** | 1970s procedural | Modern functional/OOP |
| **Type System** | Nomenclature-based | Language feature-based |

### Bottom Line

**ABAQUS demonstrates what NOT to do.** Modern languages show how to do it right.

As proud software engineers, we should call out bad design when we see it - even in commercial products. Learn from both.

---

## See Also

- [Supported Elements](elements.md) - Complete element type listing
- [Examples](examples.md) - Usage examples
- [Home](index.md) - Quick start guide
