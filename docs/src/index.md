# AbaqusReader.jl

![AbaqusReader.jl - Modern FEM Mesh Parser](assets/readme-hero.webp)

AbaqusReader.jl provides two distinct ways to read ABAQUS `.inp` files, depending on your needs.

**Design Philosophy**: We provide **topology** (geometry and connectivity), not **physics** (formulations and behavior). See our [Philosophy](philosophy.md) for why we separate these concerns.

---

```@raw html
<div style="text-align: center; margin: 2em 0; padding: 2em; background: linear-gradient(135deg, #9558B2 0%, #389826 100%); border-radius: 8px;">
  <button onclick="document.getElementById('visualizer-container').style.display='block'; this.parentElement.style.display='none';" 
          style="background: white; color: #9558B2; border: none; padding: 15px 40px; font-size: 18px; font-weight: bold; border-radius: 5px; cursor: pointer; box-shadow: 0 4px 6px rgba(0,0,0,0.1);">
    🚀 Launch Interactive Visualizer
  </button>
  <p style="color: white; margin-top: 10px; font-size: 14px;">
    Drag & drop your ABAQUS .inp files • See 3D mesh in real-time
  </p>
</div>

<div id="visualizer-container" style="display: none; margin: 2em 0;">
  <iframe src="https://ahojukka5.github.io/AbaqusReader.jl/visualizer/" 
          style="width: 100%; height: 800px; border: 2px solid #9558B2; border-radius: 8px;" 
          title="AbaqusReader.jl Interactive Visualizer">
  </iframe>
  <p style="text-align: center; margin-top: 10px;">
    <button onclick="document.getElementById('visualizer-container').style.display='none'; document.querySelector('[onclick*=visualizer-container]').parentElement.style.display='block';" 
            style="background: #9558B2; color: white; border: none; padding: 10px 20px; border-radius: 5px; cursor: pointer;">
      ✕ Close Visualizer
    </button>
  </p>
</div>
```

---

## Two Approaches for Two Different Needs

### 1. Mesh-Only Parsing - `abaqus_read_mesh()`

When you only need the **geometry and topology** (nodes, elements, sets), use this function.
It returns a simple dictionary structure containing just the mesh data - perfect for:

- Visualizing geometry
- Converting meshes to other formats
- Quick mesh inspection
- Building your own FEM implementations on top of ABAQUS geometries

### 2. Complete Model Parsing - `abaqus_read_model()`

When you need to **reproduce the entire simulation**, use this function.
It parses the complete simulation recipe including mesh, materials, boundary conditions,
load steps, and analysis parameters - everything needed to:

- Fully understand the simulation setup
- Reproduce the analysis in another solver
- Extract complete simulation definitions programmatically
- Analyze or modify simulation parameters

## Important Notes

Both functions are primarily tested with "flat" input files (the original ABAQUS input file structure).
The more structured file format describing parts, assemblies, etc. may have limited support.

The `abaqus_read_model()` function parses many common ABAQUS features but does not cover every possible
keyword and option in the ABAQUS specification. It handles typical use cases for extracting complete
simulation definitions.
