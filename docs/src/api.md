# API Reference

```@meta
DocTestSetup = quote
    using AbaqusReader
end
```

## Overview

AbaqusReader.jl exports the following main functions for working with ABAQUS input files:

- File-based API: `abaqus_read_mesh`, `abaqus_read_model` (read from .inp files)
- String-based API: `abaqus_parse_mesh`, `abaqus_parse_model` (parse from string buffers)
- Utilities: `create_surface_elements`, `abaqus_download`

## Index

```@index
```

## Exported Functions

```@docs
abaqus_read_mesh
abaqus_parse_mesh
abaqus_read_model
abaqus_parse_model
create_surface_elements
abaqus_download
```

