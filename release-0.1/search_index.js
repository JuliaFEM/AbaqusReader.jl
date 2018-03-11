var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.jl documentation",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#AbaqusReader.jl-documentation-1",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.jl documentation",
    "category": "section",
    "text": "DocTestSetup = quote\n    using AbaqusReader\nend"
},

{
    "location": "index.html#AbaqusReader.abaqus_download",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.abaqus_download",
    "category": "function",
    "text": "abaqus_download(model_name; dryrun=false)\n\nDownload ABAQUS model from Internet. model_name is the name of the input file.\n\nGiven some model name from documentation, e.g., et22sfse, download that file to local file system. This function uses environment variables to determine the download url and place of storage.\n\nIn order to use this function, one must set environment variable ABAQUS_DOWNLOAD_URL, which determines a location where to download. For example, if the path to model is https://domain.com/v6.14/books/eif/et22sfse.inp, ABAQUS_DOWNLOAD_URL will be the basename of that path, i.e., https://domain.com/v6.14/books/eif.\n\nBy default, the model will be downloaded to current directory. If that is not desired, one can set another environment variable ABAQUS_DOWNLOAD_DIR, and in that case the file will be downloaded to that directory.\n\nFunction call will return full path to downloaded file or nothing, if download is failing because of missing environment variable ABAQUS_DOWNLOAD_DIR.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.abaqus_read_mesh",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.abaqus_read_mesh",
    "category": "function",
    "text": "abaqus_read_mesh(fn::String)\n\nRead ABAQUS mesh from file fn. Returns a dict with elements, nodes, element sets, node sets and other topologically imporant things, but not the actual model with boundary conditions, load steps and so on.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.abaqus_read_model",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.abaqus_read_model",
    "category": "function",
    "text": "abaqus_read_model(filename::String)\n\nRead ABAQUS model from file. Include also boundary conditions, load steps and so on. If only mesh is needed, it\'s better to use abaqus_read_mesh insted.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.create_surface_elements",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.create_surface_elements",
    "category": "function",
    "text": "create_surface_elements(mesh, surface_name)\n\nCreate surface elements for surface using mesh mesh. Mesh can be obtained by using abaqus_read_mesh.\n\n\n\n"
},

{
    "location": "index.html#Exported-functions-1",
    "page": "AbaqusReader.jl documentation",
    "title": "Exported functions",
    "category": "section",
    "text": "AbaqusReader.abaqus_download\nAbaqusReader.abaqus_read_mesh\nAbaqusReader.abaqus_read_model\nAbaqusReader.create_surface_elements"
},

{
    "location": "index.html#AbaqusReader.parse_definition-Tuple{Any}",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.parse_definition",
    "category": "method",
    "text": "Parse string to get set type and name\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.parse_section",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.parse_section",
    "category": "function",
    "text": "Parse nodes from the lines\n\n\n\nParse elements from input lines\n\nReads element ids and their connectivity nodes from input lines. If elset definition exists, also adds the set to model.\n\n\n\nParse node and elementset from input lines\n\n\n\nParse SURFACE keyword\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.regex_match",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.regex_match",
    "category": "function",
    "text": "Custon regex to find match from string. Index used if there are multiple matches\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.add_set!",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.add_set!",
    "category": "function",
    "text": "Add set to model, if set exists\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.consumeList",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.consumeList",
    "category": "function",
    "text": "Custom list iterator\n\nSimple iterator for comsuming element list. Depending on the used element, connectivity nodes might be listed in multiple lines, which is why iterator is used to handle this problem.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.parse_numbers",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.parse_numbers",
    "category": "function",
    "text": "Parse all the numbers from string\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.register_abaqus_keyword",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.register_abaqus_keyword",
    "category": "function",
    "text": "register_abaqus_keyword(keyword::String)\n\nAdd ABAQUS keyword s to register. That is, after registration every time keyword show up in .inp file a new section is started\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.is_abaqus_keyword_registered",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.is_abaqus_keyword_registered",
    "category": "function",
    "text": "is_abaqus_keyword_registered(keyword::String)\n\nReturn true/false is ABAQUS keyword registered.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.element_mapping",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.element_mapping",
    "category": "constant",
    "text": "element_mapping\n\nThis mapping table contains information what node ids locally match each side of element.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.find_keywords",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.find_keywords",
    "category": "function",
    "text": "Find lines, which contain keywords, for example \"*NODE\"\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.matchset",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.matchset",
    "category": "function",
    "text": "Match words from both sides of \'=\' character\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.empty_or_comment_line",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.empty_or_comment_line",
    "category": "function",
    "text": "Checks for a comment or empty line\n\nFunction return true, if line starts with comment character \"**\" or has length of 0\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.create_surface_element",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.create_surface_element",
    "category": "function",
    "text": "Given element code, element side and global connectivity, determine boundary element. E.g. for Tet4 we have 4 sides S1..S4 and boundary element is of type Tri3.\n\n\n\n"
},

{
    "location": "index.html#AbaqusReader.parse_abaqus",
    "page": "AbaqusReader.jl documentation",
    "title": "AbaqusReader.parse_abaqus",
    "category": "function",
    "text": "Main function for parsing Abaqus input file.\n\nFunction parses Abaqus input file and generates a dictionary of all the available keywords.\n\n\n\n"
},

{
    "location": "index.html#Internal-functions-1",
    "page": "AbaqusReader.jl documentation",
    "title": "Internal functions",
    "category": "section",
    "text": "AbaqusReader.parse_definition(definition)\nAbaqusReader.parse_section\nAbaqusReader.regex_match\nAbaqusReader.add_set!\nAbaqusReader.consumeList\nAbaqusReader.parse_numbers\nAbaqusReader.register_abaqus_keyword\nAbaqusReader.is_abaqus_keyword_registered\nAbaqusReader.element_mapping\nAbaqusReader.find_keywords\nAbaqusReader.matchset\nAbaqusReader.empty_or_comment_line\nAbaqusReader.create_surface_element\nAbaqusReader.parse_abaqus"
},

{
    "location": "index.html#Index-1",
    "page": "AbaqusReader.jl documentation",
    "title": "Index",
    "category": "section",
    "text": ""
},

]}
