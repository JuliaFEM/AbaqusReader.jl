# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/JuliaFEM.jl/blob/master/LICENSE.md

let register=Set{String}()

"""
    register_abaqus_keyword(keyword::String)

Add ABAQUS keyword `s` to register. That is, after registration every time
keyword show up in `.inp` file a new section is started
"""
global function register_abaqus_keyword(keyword::String)
    push!(register, keyword)
    return Type{Val{Symbol(keyword)}}
end

"""
    is_abaqus_keyword_registered(keyword::String)

Return true/false is ABAQUS keyword registered.
"""
global function is_abaqus_keyword_registered(keyword::String)
    return keyword in register
end

end
