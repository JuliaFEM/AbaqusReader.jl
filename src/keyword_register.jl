# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/AbaqusReader.jl/blob/master/LICENSE

const REGISTERED_KEYWORDS = Set{String}()

"""
    register_abaqus_keyword(keyword::String)

Add ABAQUS keyword `s` to register. That is, after registration every time
keyword show up in `.inp` file a new section is started
"""
function register_abaqus_keyword(keyword::String)
    push!(REGISTERED_KEYWORDS, keyword)
    return Val{Symbol(keyword)}
end

"""
    is_abaqus_keyword_registered(keyword::String)

Return true/false is ABAQUS keyword registered.
"""
function is_abaqus_keyword_registered(keyword::String)
    return keyword in REGISTERED_KEYWORDS
end
