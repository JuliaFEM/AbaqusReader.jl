# GitHub Copilot Instructions for AbaqusReader.jl

## Package Philosophy

AbaqusReader.jl is designed around **two distinct use cases** that should never be conflated:

### 1. Mesh-Only Parsing (`abaqus_read_mesh`)
**Purpose**: Extract only geometry and topology  
**Returns**: Simple `Dict` structure  
**Use when**: Users need nodes, elements, sets, and surfaces for visualization, conversion, or building custom FEM implementations

**Key principle**: Keep it simple, fast, and lightweight. No physics, no materials, no boundary conditions.

### 2. Complete Model Parsing (`abaqus_read_model`)
**Purpose**: Extract the complete simulation recipe  
**Returns**: Structured `Model` object  
**Use when**: Users need to reproduce or understand the entire simulation setup

**Key principle**: Everything needed to reproduce the simulation - mesh, materials, properties, boundary conditions, load steps, and analysis parameters.

## Design Principles

### Simplicity Over Cleverness
- **Prefer dictionaries over complex type dispatch** when it doesn't hurt performance
- **Direct function calls over Val-based dispatch** for maintainability
- **Clear function names** over generic ones (e.g., `open_solid_section!` not `open_section!(::TYPE)`)
- This is a **parser, not a performance-critical solver** - prioritize clarity

### Modern Julia Idioms (Julia 1.0+)
- Use `Union{T, Nothing}` instead of deprecated `Nullables`
- Use `===` for `nothing` checks, not `==`
- Prefer `@debug "message"` over `@debug("message")`
- Use `const` for module-level data structures
- Avoid `global` mutable state

### Backward Compatibility
- The **public API must remain stable**: `abaqus_read_mesh()` and `abaqus_read_model()`
- Return types (Dict for mesh, Model for complete) must not change
- Internal refactoring is encouraged as long as tests pass

### Code Organization
- **Element type information**: Single dictionary in `parse_mesh.jl` (ELEMENT_INFO)
- **Keyword handling**: Direct dispatch in `parse_model.jl`, no complex registration
- **Each function does one thing**: Parse one section type, handle one keyword

## What to Keep in Mind

### When Adding New Element Types
1. Add one line to `ELEMENT_INFO` dictionary in `parse_mesh.jl`
2. Map ABAQUS element name → (num_nodes, generic_type)
3. That's it. No need for multiple functions.

### When Adding New Element Types
1. **Don't edit code** - add to `src/abaqus_elements.toml` instead
2. Find ABAQUS element documentation for node count and topology
3. Add entry to appropriate section in TOML file:
   ```toml
   [ELEMENT_NAME]
   nodes = <count>
   type = "<GenericType>"
   description = "<optional>"
   ```
4. Add test in `test/test_parse_mesh.jl` to verify it works
5. Element is automatically available - no code changes needed!

### When Adding New Keywords
1. Add to `RECOGNIZED_KEYWORDS` Set in `parse_model.jl`
2. Add handler in `maybe_open_section!` or `maybe_close_section!`
3. Create specific handler function like `open_material!` or `close_elastic!`
4. Keep it straightforward - no Val dispatch needed

### When Refactoring
- **Run tests frequently**: All 96 tests must pass
- **Check both APIs**: Test both `abaqus_read_mesh` and `abaqus_read_model`
- **Preserve return types**: Dict structure for mesh, Model object for complete
- **Commit atomically**: One logical change per commit with clear messages

### What NOT to Do
- ❌ Don't add back deprecated dependencies (Nullables.jl)
- ❌ Don't create complex Val-based dispatch unless absolutely necessary
- ❌ Don't use global mutable state
- ❌ Don't conflate mesh parsing with model parsing
- ❌ Don't import Base methods without proper extensions
- ❌ Don't sacrifice clarity for minor performance gains in parsing code
- ❌ Don't hardcode element types in parse_mesh.jl - use the TOML database

## File Responsibilities

- **`abaqus_elements.toml`**: Element type database - easy to extend without code changes
- **`parse_mesh.jl`**: Mesh-only parsing, loads element database from TOML, simple Dict returns
- **`parse_model.jl`**: Complete model parsing, type definitions, structured Model returns
- **`create_surface_elements.jl`**: Extract boundary faces from volume elements
- **`abaqus_download.jl`**: Download example files from remote sources
- **`AbaqusReader.jl`**: Main module, exports public API
- **`ELEMENT_DATABASE.md`**: Documentation for adding new element types

## Testing Philosophy

- Tests are in `/test` directory
- All changes must pass: `julia --project=. -e 'using Pkg; Pkg.test()'`
- 96 tests cover both parsing modes and various element types
- Don't break backward compatibility - tests verify the API contract

## Common Patterns

### Parsing a New Section Type
```julia
# In parse_mesh.jl or parse_model.jl
function parse_section(model, lines, ::Symbol, idx_start, idx_end, ::Type{Val{:NEWSECTION}})
    # Parse lines between idx_start and idx_end
    # Update model dictionary/object
    # Return nothing
end
```

### Adding Keywords (parse_model.jl only)
```julia
# 1. Add to RECOGNIZED_KEYWORDS
const RECOGNIZED_KEYWORDS = Set([
    "EXISTING", "KEYWORDS", ...,
    "NEW KEYWORD"
])

# 2. Add handler
function maybe_open_section!(model, state)
    section_name = state.section.name
    if section_name == "NEW KEYWORD"
        open_new_keyword!(model, state)
    # ... existing conditions
    end
end

# 3. Implement handler
function open_new_keyword!(model, state)
    # Do the actual work
end
```

## Remember

**The vision is clear**: Simple mesh extraction when that's all you need, or complete simulation definition when you need to reproduce the entire analysis. Keep these two paths distinct and well-maintained.

This is a mature, stable package serving the JuliaFEM ecosystem. Changes should improve clarity and maintainability while preserving the proven API that users depend on.
