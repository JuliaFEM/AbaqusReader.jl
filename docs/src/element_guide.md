# Element Selection Guide

Choosing the right element type is crucial for accurate and efficient finite element analysis. This guide provides practical recommendations based on ABAQUS documentation and best practices.

## General Principles

### First-Order vs. Second-Order Elements

**First-order elements** (linear interpolation):

- ✅ Fewer degrees of freedom → faster computation
- ✅ Work well with fine meshes
- ⚠️ Require more elements for similar accuracy
- ⚠️ Can exhibit locking in bending or with incompressible materials

**Second-order elements** (quadratic interpolation):

- ✅ Higher accuracy with coarser meshes
- ✅ Better capture stress concentrations and curved geometry
- ✅ Less susceptible to locking
- ⚠️ More expensive per element
- ⚠️ May need more integration points

**Rule of thumb:** Use second-order elements when accuracy matters and you can afford coarser meshes. Use first-order elements with fine meshes when computational speed is critical.

### Full vs. Reduced Integration

**Full integration:**

- ✅ Stable, no hourglassing
- ✅ Better for distorted meshes
- ⚠️ More expensive computationally
- ⚠️ May exhibit locking (shear, volumetric)

**Reduced integration (R suffix):**

- ✅ Faster - significantly reduces computation time
- ✅ Less susceptible to locking
- ⚠️ May exhibit hourglassing (needs hourglass control)
- ⚠️ Requires reasonably fine mesh

**Rule of thumb:** Reduced integration is generally recommended for most analyses (e.g., C3D8R, S4R, CPE4R) as ABAQUS includes hourglass control. Use full integration if you have severely distorted elements.

## 3D Solid Elements

### Tetrahedral Elements: What to Use

**❌ AVOID: C3D4, C3D4H**

- Linear tetrahedra are overly stiff and exhibit slow convergence
- Use ONLY as filler elements in low-stress regions far from areas of interest
- "Should be avoided" according to ABAQUS documentation

**✅ USE: C3D10, C3D10M**

- C3D10: Standard second-order tetrahedron, good general-purpose element
- C3D10M: **Recommended choice** - minimal locking, excellent in contact, works well with large deformations
- C3D10R: Alternative with reduced integration, but may develop volumetric locking with nearly incompressible materials

**When to use hybrid (H suffix):**

- C3D10H: Use only when material is nearly incompressible (Poisson's ratio > 0.475)
- Significantly more expensive than non-hybrid versions
- Prevents volumetric locking in plastic deformation

### Hexahedral Elements: The Workhorses

**For general analysis:**

1. **C3D8R** - **Most popular choice**
   - Reduced integration with hourglass control
   - Significantly faster than full integration
   - Use with reasonably fine mesh
   - Excellent balance of accuracy and efficiency

2. **C3D20R** - **Best accuracy with coarse mesh**
   - Second-order with reduced integration
   - Generally more accurate than C3D20 (full integration)
   - Roughly 3.5× faster than C3D20
   - Recommended for smooth problems

3. **C3D8I** - **Bending-dominated problems**
   - Incompatible modes eliminate parasitic shear in bending
   - Best if elements maintain rectangular shape
   - Use caution with large compressive strains

**For special cases:**

- **C3D8H, C3D20H, C3D8RH, C3D20RH**: Nearly incompressible materials (rubber, metal plasticity at large strains)
- **C3D8**: Full integration, use if mesh has severely distorted elements
- **C3D20E**: Enhanced formulation for specific applications

### Wedge Elements: Transition Elements

**C3D6**:

- ❌ Generally avoid - use only to complete a mesh topology
- Should be far from regions needing accurate results
- Requires very fine meshing for acceptable accuracy

**C3D15**:

- ✅ Acceptable for transitioning between different mesh densities
- Second-order provides reasonable accuracy
- Use sparingly, prefer hex elements when possible

## Shell Elements

### Triangular Shells

**S3, S3R, STRI3**:

- Use only when triangular mesh is unavoidable
- Linear elements need fine mesh

**STRI65**:

- ✅ Better choice for triangular shells
- Quadratic interpolation provides good accuracy

**General rule:** Prefer quadrilateral shells over triangular when possible.

### Quadrilateral Shells

**S4R** - **Recommended for most applications**

- Reduced integration with hourglass control
- Excellent balance of accuracy and efficiency
- Works well for both thin and thick shells
- Most widely used shell element

**S4**:

- Full integration alternative
- Use if elements are severely distorted

**S8R**:

- Quadratic element for high accuracy requirements
- Better captures stress concentrations
- Better for modeling curved surfaces
- More expensive than S4R

## 2D Continuum Elements

### Plane Stress, Plane Strain, and Axisymmetric

The selection principles are similar across CPS, CPE, and CAX families:

**❌ AVOID Linear Triangles (CPS3, CPE3, CAX3):**

- Constant stress elements, overly stiff
- Use only as filler in noncritical regions
- Exhibit slow convergence

**✅ RECOMMENDED for most analyses:**

- **CPS4R, CPE4R, CAX4R**: Reduced integration quads - most commonly used
- **CPS8R, CPE8R, CAX8R**: Second-order for higher accuracy

**Special formulations:**

- **CPS4I, CPE4I, CAX4I**: Incompatible modes for bending-dominated problems (best with rectangular shapes)
- **CPS6, CPE6, CAX6**: Modified triangles when automatic mesh generators create triangular meshes

### Plane Stress vs. Plane Strain vs. Axisymmetric

**Use Plane Stress (CPS):**

- Thin plates loaded in their plane
- One stress component is negligible (σ₃₃ ≈ 0)
- Example: Sheet metal forming, thin panels

**Use Plane Strain (CPE):**

- Long structures with uniform cross-section
- No strain in out-of-plane direction (ε₃₃ = 0)
- Example: Dams, tunnels, retaining walls, long pipes

**Use Axisymmetric (CAX):**

- Rotationally symmetric geometry AND loading
- Example: Pressure vessels, containers, tires under uniform loading

## Beam and Truss Elements

### Trusses (T2D2, T3D2)

- Pin-jointed structures carrying only axial loads
- No bending, shear, or torsion
- Example: Space frames, towers, roof trusses

### Beams

**B31** - **Timoshenko beam**

- Includes transverse shear deformation
- Use for general 3D beam/frame analysis
- Better for shorter, stockier beams

**B33** - **Euler-Bernoulli beam**

- No transverse shear (shear deformation neglected)
- Better for slender beams (length/depth > 10)
- Cubic interpolation for deflection

**B32** - **Quadratic Timoshenko beam**

- Quadratic interpolation
- Better for curved beams
- Improved accuracy for bending-dominated problems

## Material-Specific Considerations

### Nearly Incompressible Materials (ν ≥ 0.475)

**Problem:** Standard elements exhibit volumetric locking

**Solutions:**

1. **Hybrid elements (H suffix)**: C3D8H, C3D10H, C3D20H, etc.
   - Independent pressure interpolation
   - Prevents volumetric locking
   - More expensive computationally

2. **Reduced integration**: C3D8R, C3D20R
   - Less susceptible to locking
   - May still lock with very high Poisson's ratios

3. **Modified elements**: C3D10M
   - Minimal volumetric locking
   - Good performance in plasticity

**Examples:** Rubber (ν ≈ 0.499), metals in plastic deformation (ν = 0.5 in plastic range)

### Contact Problems

**Recommended elements:**

- **C3D10M**: Excellent in contact, minimal locking
- **C3D8R**: With fine enough mesh
- **CPE6, CPS6, CAX6**: Modified triangles work well in contact

**Avoid:**

- Linear triangles and tetrahedra (too stiff)
- Elements with incompatible modes may have issues at contact interfaces

## Mesh Quality Considerations

### Element Shape

**Hexahedra and Quads:**

- Aim for aspect ratio < 3:1 (< 10:1 acceptable)
- Interior angles: 45° to 135° (90° ideal)
- Avoid extreme tapering

**Incompatible mode elements (I suffix):**

- Work best with approximately rectangular shapes
- Performance degrades with parallelogram-shaped elements

### Reduced Integration Elements

Reduced integration requires reasonably fine meshes to control hourglassing:

- Use at least 3-4 elements through thickness for bending
- Avoid single-element models with reduced integration
- ABAQUS includes hourglass control automatically

## Performance vs. Accuracy Trade-offs

### For speed-critical applications:

1. C3D8R, C3D20R (not C3D8, C3D20)
2. S4R (not S4 or S8R)
3. CPE4R, CPS4R, CAX4R

### For accuracy-critical applications:

1. C3D20R, C3D10M (not C3D4 or C3D8)
2. S8R (not S3 or S4)
3. CPE8R, CPS8R, CAX8R

### For difficult problems (near-incompressibility, contact, large deformation):

1. C3D10M, C3D8H, C3D20H
2. CPE6, CPS6, CAX6
3. Avoid linear triangles/tets

## Quick Reference Table

| Problem Type | First Choice | Second Choice | Avoid |
|-------------|--------------|---------------|-------|
| General 3D | C3D8R, C3D20R | C3D10M | C3D4, C3D6 |
| 3D + incompressible | C3D10M, C3D8H | C3D20H | C3D4, C3D4H |
| 3D + contact | C3D10M | C3D8R (fine mesh) | C3D4, C3D8I |
| Shells | S4R | S8R | S3 |
| Plane stress | CPS4R, CPS8R | CPS6 | CPS3 |
| Plane strain | CPE4R, CPE8R | CPE6 | CPE3 |
| Axisymmetric | CAX4R, CAX8R | CAX6 | CAX3 |
| Bending | C3D20R, C3D8I | S8R | C3D4, CPS3 |
| Trusses | T3D2, T2D2 | - | - |
| Beams | B31 (short), B33 (slender) | B32 | - |

## Summary

**Golden Rules:**

1. 🎯 Prefer quadrilaterals/hexahedra over triangles/tetrahedra
2. 🚀 Use reduced integration (R) for efficiency - it's usually more accurate too
3. 🔒 Use hybrid (H) or modified (M) elements for near-incompressibility
4. 📐 Second-order elements allow coarser meshes with good accuracy
5. ⛔ Avoid C3D4, CPS3, CPE3, CAX3 except as filler
6. ⚙️ C3D8R, S4R, CPE4R are the workhorses - use them for general analysis
7. 🎯 C3D10M is excellent for difficult problems (contact, large deformation)

When in doubt, start with the "first choice" from the quick reference table and refine based on results.
