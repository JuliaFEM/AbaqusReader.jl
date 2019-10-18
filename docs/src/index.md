# AbaqusReader.jl

ABAQUS input file (.inp) is a very common file format to describe finite element
models in the industry. The file is used to control the whole numerical
simulation, including mesh definition, material parameters, and other simulation
parameters.

`AbaqusReader.jl` is a package designed to parse simulation data defined in the
ABAQUS input file. The package offers two different approaches to parsing,
depending on the user's needs. The first one is to parse only mesh data, and
another approach is a somewhat more complex approach trying to parse the whole
model.

The main commands for package are `abaqus_read_mesh`, which parses only the mesh
part of the input file and returning a simple dictionary containing all relevant
mesh data so that user can read the model using own FEM parser. Another command
is `abaqus_read_model` which is used to read the whole model. Both of the
commands are demonstrated in the Examples section. It should be pointed out that
`abaqus_read_model` is highly incomplete as it turned out that it would take a
huge amount of work to parse an entire model.

Also, both functions are tested only with "flat" input files, which is the
original ABAQUS input file structure. The more structured file format,
describing parts, etc. is not tested with the package.
