# AbaqusReader.jl API Documentation

```@meta
DocTestSetup = quote
    using AbaqusReader
end
```

## Index

```@index
```

## Exported functions

```@docs
AbaqusReader.abaqus_download
AbaqusReader.abaqus_read_mesh
AbaqusReader.abaqus_read_model
AbaqusReader.create_surface_elements
```

## Internal functions

```@docs
AbaqusReader.parse_definition(definition)
AbaqusReader.parse_section
AbaqusReader.regex_match
AbaqusReader.add_set!
AbaqusReader.consumeList
AbaqusReader.parse_numbers
AbaqusReader.register_abaqus_keyword
AbaqusReader.is_abaqus_keyword_registered
AbaqusReader.element_mapping
AbaqusReader.find_keywords
AbaqusReader.matchset
AbaqusReader.empty_or_comment_line
AbaqusReader.create_surface_element
AbaqusReader.parse_abaqus
```

