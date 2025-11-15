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

## Why This Is Wrong: SOLID Principles Violated

ABAQUS's element design is a textbook example of **violating every SOLID principle** from object-oriented design. Let's examine each violation:

### **S** - Single Responsibility Principle ❌

**Principle**: "A class should have one, and only one, reason to change."

**ABAQUS Violation**: Each element type has multiple responsibilities:
- Topology (geometric shape and connectivity)
- Physics formulation (stress state, material behavior)
- Integration scheme (quadrature rules)
- Special features (hybrid, incompatible modes)

```fortran
! CPS3 is responsible for ALL of these:
SUBROUTINE CPS3_STIFFNESS(...)
  ! Topology: 3-node triangle shape functions
  ! Physics: Plane stress constitutive equations
  ! Integration: Gauss quadrature
  ! Assembly: Element stiffness contribution
END
```

**Consequence**: Change anything → must modify the entire element type. Want reduced integration? Create `CPS3R`. Want hybrid formulation? Create `CPS3H`. Exponential explosion.

### **O** - Open/Closed Principle ❌

**Principle**: "Software should be open for extension, closed for modification."

**ABAQUS Violation**: Cannot add new physics without modifying the codebase:

```
Want new physics formulation?
1. Create N new element types (one per topology)
2. Modify element registry
3. Duplicate shape functions and integration
4. Update documentation, tests, manuals
```

**Modern approach** (extension without modification):
```julia
# Add new physics - zero modifications to existing code
struct HyperelasticFormulation end

function stiffness(elem::Tri3, phys::HyperelasticFormulation, integ::FullIntegration)
    # New behavior via multiple dispatch
    # Tri3 code unchanged
end
```

### **L** - Liskov Substitution Principle ❌

**Principle**: "Derived classes must be substitutable for their base classes."

**ABAQUS Violation**: Cannot substitute `CPS3` for `CPE3` even though they're the same topology:

```fortran
! These SHOULD be interchangeable (same topology)
! But they're not - different physics hardcoded
CALL ELEMENT_STIFFNESS(elem_type='CPS3', ...)  ! Plane stress
CALL ELEMENT_STIFFNESS(elem_type='CPE3', ...)  ! Plane strain

! Cannot substitute! Different hardcoded behavior
```

**Modern approach** (proper substitution):
```julia
# Same topology, different physics - fully substitutable
function solve(topology::Triangle3Node, physics::PhysicsModel)
    # Topology is substitutable, physics is parameter
end

solve(Tri3([1,2,3]), PlaneStress())   # ✓ Works
solve(Tri3([1,2,3]), PlaneStrain())   # ✓ Same topology, different physics
```

### **I** - Interface Segregation Principle ❌

**Principle**: "Clients shouldn't depend on interfaces they don't use."

**ABAQUS Violation**: Element types expose everything even when only topology is needed:

```fortran
! Just need connectivity for visualization
CALL GET_ELEMENT_NODES(elem_type='C3D20', ...)

! But C3D20 includes:
! - 20-node hexahedron topology          (NEEDED)
! - 3D stress formulation                (NOT NEEDED)
! - Quadratic shape functions            (NOT NEEDED)
! - Integration point data               (NOT NEEDED)
! - Material interface                   (NOT NEEDED)

! Fat interface - 80% irrelevant for this use case
```

**Modern approach** (segregated interfaces):
```julia
# Topology interface (what AbaqusReader provides)
topology = Hex20([1,2,3,...,20])  # Just connectivity
nodes = get_nodes(topology)        # Simple, focused interface

# Physics interface (user adds if needed)
physics = ThreeDimensionalStress()
stiffness = compute(topology, physics)  # Separate concerns
```

### **D** - Dependency Inversion Principle ❌

**Principle**: "Depend on abstractions, not concretions."

**ABAQUS Violation**: Everything depends on concrete element type names:

```fortran
! Tight coupling to concrete types
IF (elem_type == 'CPS3') THEN
  CALL CPS3_ROUTINE(...)
ELSEIF (elem_type == 'CPE3') THEN
  CALL CPE3_ROUTINE(...)
ELSEIF (elem_type == 'CAX3') THEN
  CALL CAX3_ROUTINE(...)
! ... 240+ more cases
ENDIF

! Cannot abstract! Concrete type names everywhere
```

**Modern approach** (depend on abstractions):
```julia
# Abstract interfaces
abstract type Element end
abstract type Physics end

# Concrete implementations
struct Tri3 <: Element end
struct PlaneStress <: Physics end

# Depend on abstraction, not concretions
function stiffness(elem::Element, phys::Physics)
    # Works with ANY element and physics type
    # Multiple dispatch resolves concrete behavior
end
```

---

## SOLID Violations Summary

| **Principle** | **ABAQUS Violation** | **Consequence** |
|---------------|----------------------|-----------------|
| **S**ingle Responsibility | Element types do topology + physics + integration | Change one aspect → modify entire type |
| **O**pen/Closed | Cannot extend without modifying codebase | Adding features requires code changes |
| **L**iskov Substitution | Same topology types not substitutable | Cannot abstract over topology |
| **I**nterface Segregation | Fat interfaces expose everything | Clients depend on unused functionality |
| **D**ependency Inversion | Depends on concrete type names | Tight coupling, hard to abstract |

**Result**: **Unmaintainable, unextensible, O(exponential) complexity.**

---

## Additional Design Violations

### Violates Separation of Concerns

Topology and physics are **orthogonal** - they vary independently, but ABAQUS couples them.

### Violates DRY (Don't Repeat Yourself)

```fortran
! Same shape functions duplicated across physics variants
SUBROUTINE CPS3_STIFFNESS(...)
  ! Shape functions for 3-node triangle
END

SUBROUTINE CPE3_STIFFNESS(...)
  ! Shape functions for 3-node triangle  (DUPLICATED!)
END

SUBROUTINE CAX3_STIFFNESS(...)
  ! Shape functions for 3-node triangle  (DUPLICATED!)
END
```

### Not Composable

Modern software composes behavior:
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

ABAQUS is a **perfect case study** for teaching software engineering principles because it demonstrates clear violations of established best practices.

### What This Demonstrates

1. **SOLID Principles** - All five violated in one design
2. **Separation of Concerns** - Orthogonal dimensions mixed together
3. **Complexity Analysis** - Exponential vs. linear growth patterns
4. **Technical Debt** - How poor decisions compound over decades
5. **Type System Design** - Using language features vs. nomenclature hacks
6. **Maintainability** - Why extensibility matters from day one

### Design Review Questions

When reviewing any software design, ask these questions:

#### 1. **Single Responsibility**
- Does each class/type have exactly one reason to change?
- Are multiple concerns bundled together?
- **ABAQUS Example**: Element types mix topology + physics + integration

#### 2. **Open/Closed**
- Can I add features without modifying existing code?
- Will adding dimension X require creating N×M variants?
- **ABAQUS Example**: New physics → must create N new element types

#### 3. **Liskov Substitution**
- Are similar types truly interchangeable?
- Can I abstract over categories?
- **ABAQUS Example**: CPS3 and CPE3 both triangles, but not substitutable

#### 4. **Interface Segregation**
- Do clients depend on functionality they don't use?
- Are interfaces fat or focused?
- **ABAQUS Example**: Need topology? Get physics too (unwanted)

#### 5. **Dependency Inversion**
- Do I depend on abstractions or concrete types?
- Am I coupled to specific implementations?
- **ABAQUS Example**: Hardcoded element type name strings everywhere

#### 6. **Are Concerns Orthogonal?**
- Do these dimensions vary independently?
- If YES → Separate types that compose
- If NO → Single abstraction may be OK
- **ABAQUS Example**: Topology and physics are orthogonal but coupled

#### 7. **Am I Creating Exponential Complexity?**
- Will adding dimension X require variants of all Y?
- If YES → You're creating exponential explosion
- If NO → Good, concerns are separated
- **ABAQUS Example**: T × P × I × F = 240+ types

### The Lessons

| **❌ Don't Do This (ABAQUS)** | **✅ Do This (Modern)** |
|-------------------------------|------------------------|
| Violate all five SOLID principles | Follow SOLID for maintainability |
| Mix orthogonal concerns in type names | Separate concerns into independent types |
| Use nomenclature instead of type system | Use language features (templates/traits/dispatch) |
| Duplicate code across variants | Compose at call site |
| Create O(exponential) type proliferation | Design for O(linear) extensibility |
| Design for immediate needs only | Design for growth from day one |
| Let compatibility prevent improvement | Refactor early before debt compounds |
| Depend on concrete type names | Depend on abstractions |

### Teaching Exercise

**Give students this scenario**: "You're designing a FEM library. You need to support:
- 10 element topologies (triangles, quads, tets, hexes, etc.)
- 5 physics formulations (plane stress, plane strain, 3D, axisymmetric, shells)
- 3 integration schemes (full, reduced, selective)
- 2 special features (hybrid, incompatible modes)

**Bad approach (ABAQUS style)**: Create 10 × 5 × 3 × 2 = **300 element type classes**

**Good approach (modern style)**: Create 10 + 5 + 3 + 2 = **20 types that compose**

**Discussion points**:
- Which violates SOLID? (Bad approach violates all five)
- Which is easier to extend? (Good approach: add one type, not 60)
- Which has less code duplication? (Good approach: DRY)
- What happens when you add dimension 5? (Bad: 300→1500 types, Good: 20→25 types)

---

## Summary: ABAQUS as a Warning

| Aspect | ABAQUS (Wrong) | Modern Approach (Right) |
|--------|----------------|------------------------|
| **SOLID Principles** | Violates all five | Follows all five |
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
