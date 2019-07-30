#=
Functions in this file take strings which are chunks of xml and ml (as used by Mathcad).
They return Julia values.
Internally, the chunks are converted to xml documents.
=#

UNITDIC = Dict{String, FreeUnits}()
push!(UNITDIC, "nanometer" => nm,  "micrometer" => μm,  "micron" => μm,  "millimeter" => mm,  "centimeter" => cm)
push!(UNITDIC, "desimeter" => dm,  "meter" => m,  "kilometer" => km,  "megameter" => Mm,  "gigameter" => Gm,  "terameter" => Tm)
push!(UNITDIC, "petameter" => Pm,  "nanosecond" => ns,  "microsecond" => μs,  "mikrosecond" => μs,  "millisecond" => ms)
push!(UNITDIC, "second" => s,  "milligram" => mg,  "centigram" => cg,  "kilogram" => kg,  "rad" => rad,  "degree" => °) 
push!(UNITDIC, "kelvin" => K,  "rankine" => Ra,  "minute" => minute,  "d" => d,  "atm" => atm,  "bar" => bar,  "newton" => N)
push!(UNITDIC, "decanewton" => daN,  "kilonewton" => kN,  "meganewton" => MN,  "giganewton" => GN,  "pascal" => Pa)
push!(UNITDIC, "kilopascal" => kPa,  "megapascal" => MPa,  "gigapascal" => GPa,  "joule" => J,  "kilojoule" => kJ) 
push!(UNITDIC, "megajoule" => MJ,  "gigajoule" => GJ,  "Nmm" => Nmm,  "Nm" => Nm,  "decaNm" => daNm,  "kiloNm" => kNm)
push!(UNITDIC, "megaNm" => MNm,  "gigaNm" => GNm,  "inch" => inch,  "foot" => ft,  "pound" => lb,  "pound_force" => lbf)
push!(UNITDIC, "°C" => °C,  "°F" => °F,  "h" => h,  "yr" => yr,  "l" => l,  "desil" => dl,  "centil" => cl,  "millil" => ml)
push!(UNITDIC, "gravitational_acceleration" => g,  "kip" => kip,  "shton" => shton)

JUFOODIC = Dict{String, Symbol}()
push!(JUFOODIC, "pow" => :^)
push!(JUFOODIC, "div" => :/)

FOODIC = Dict{String, Function}()

function ev_eval(xe)
    @assert name(xe) == "eval"
    che = xe |> child_elements_ignore_provenance
    @assert name(che[1]) ∈ ["apply", "matrix"] " unknown structure\n $xe"
    if length(che) == 2
        @assert name(che[2]) == "result"
        ev(che[2])
    elseif length(che) == 3
        @assert name(che[2]) == "unitOverride"
        @assert name(che[3]) == "result"
        resu = ev(che[3])
        unitoverride = ev(che[2])
        if has_no_units(resu)
            return resu * unitoverride
        else
            @assert is_dimension_compatible(resu, unitoverride)
            return resu |> unitoverride
        end
    else
        @warn "Not implemented eval structure"#\n $xe"
        1
    end
end
push!(FOODIC, "eval" => ev_eval)


function ev_real(xe)
    @assert name(xe) == "real"
    nos = xe |> child_nodes |> collect
    @assert length(nos) == 1 " several in this element\n $xe"
    no =  nos|> first
    @assert is_textnode(no)
    no |> content |> Meta.parse
end
push!(FOODIC, "real" => ev_real)


function ev_str(xe)
    @assert name(xe) == "str"
    nos = xe |> child_nodes |> collect
    @assert length(nos) == 1 " several in this element\n $xe"
    no =  nos|> first
    @assert is_textnode(no)
    no |> content |> String
end
push!(FOODIC, "str" => ev_str)

function ev_unitedValue(xe)
    che = xe |> child_elements_ignore_provenance
    @assert  length(che) == 2
    if che[1] |> name ∉ ["real", "matrix"]
        @warn " might not compute, not a real. Name: $(name(che[1])) \n\n $xe"
    end
    @assert che[2] |> name == "unitMonomial"
    valu = ev(che[1])
    @assert has_no_units(valu) valu xe
    unitmonomial = ev(che[2])
    valu * unitmonomial
    #=
    defaultunits = unitmonomial |> dimension |> upreferred
    (valu * defaultunits ) |>  unitmonomial
    =#
end
push!(FOODIC, "unitedValue" => ev_unitedValue)

function ev_unitMonomial(xe)
    che = xe |> child_elements_ignore_provenance
    mapreduce(ev, *, che)
end
push!(FOODIC, "unitMonomial" => ev_unitMonomial)

function ev_unitReference(xe)
    @assert name(xe) == "unitReference"
    @assert has_attribute(xe, "unit")
    u = attribute(xe, "unit")
    @assert haskey(UNITDIC, u) u
    if has_attribute(xe, "power-numerator")
        exponent = attribute(xe, "power-numerator") |> Meta.parse
        return get(UNITDIC, u, NaN)^exponent
    else
        return get(UNITDIC, u, NaN)
    end
end
push!(FOODIC, "unitReference" => ev_unitReference)


function ev_unitOverride(xe)
    @assert name(xe) == "unitOverride"
    che = xe |> child_elements_ignore_provenance
    @assert length(che) == 1 " not implemented number of children: \n$xe"
    @assert !has_attributes(xe)  " There are attributes: \n$xe"
    return che[1] |> ev |> ev_existing
end
push!(FOODIC, "unitOverride" => ev_unitOverride)

"""
This duplicates read_m15_file.jl, where it's called 'id', with other tests.
Althought it behaves similarly, the path to this element is different.
Here, the id is expected to be a reference to a predefined variable.
The existence of the refence is checked in the calling context.
"""
function ev_id(xe)
    @assert name(xe) == "id"
    che = xe |> child_elements_ignore_provenance
    @assert length(che) == 0 " not implemented: \n$xe"
    @assert has_children(xe) " no children $xe" 
    textnode = first(child_nodes(xe))
    @assert is_textnode(textnode) " first child is not a textnode $xe"
    sub = attribute(xe, "subscript")
    if sub == nothing
        na = Symbol(content(textnode))
    else
        @warn "Unexpected in this context?"
        na = Symbol(content(textnode), "_" *replace(sub, "." => "_"))
    end
    na
end
push!(FOODIC, "id" => ev_id)


function ev_result(xe)
    @assert name(xe) == "result"
    che = xe |> child_elements_ignore_provenance
    @assert  che |> length == 1
    ev(che[1])
end
push!(FOODIC, "result" => ev_result)

function ev_define(xe)
    @assert name(xe) == "define"
    che = xe |> child_elements_ignore_provenance
    @assert  che |> length == 2
    ev(che[2])
end
push!(FOODIC, "define" => ev_define)


function ev_matrix(xe)
    @assert name(xe) == "matrix"
    @assert has_attribute(xe, "rows")
    @assert has_attribute(xe, "cols")
    rows = attribute(xe, "rows") |> Meta.parse
    cols = attribute(xe, "cols") |> Meta.parse
    che = xe |> child_elements_ignore_provenance
    mixtypevector = ev.(che)
    vector = [promote(mixtypevector...)...]
    reshape(vector, (rows, cols))
end
push!(FOODIC, "matrix" => ev_matrix)

"The apply element defines calls to a very large selection of functions,
including user defined functions.
For evaluating stored results, the number of possible functions is much lower
and easy to implement as corresponding Julia functions."
function ev_apply(xe)
    @assert name(xe) == "apply"
    che = xe |> child_elements_ignore_provenance
    if length(che) == 3
        # TODO find the other values of "fixity" attribute: infix, postfix, prefix, ?
        # It does not at first glance seem to affect the xml structure.
        @assert !has_attributes(che[1])
        @assert !has_children(che[1])
        foo = name(che[1])
        jufusym = get(JUFOODIC, foo, " not in JUFOODIC: $foo")
        jufu = jufusym |> ev_existing
        arg1 = che[2] |> ev |> ev_existing
        arg2 = che[3] |> ev |> ev_existing
        @assert jufu isa Function jufu arg1 arg2
        return jufu(arg1, arg2)
    else
        @warn " not implemented structure \n $xe"
        return NaN
    end
end
push!(FOODIC, "apply" => ev_apply)



function ev_unknown(xe)
    @info "No ev_$(name(xe))"
    1
end

"Evaluate structured ML math recursively"
ev(xe::XMLElement) = get(FOODIC, name(xe), ev_unknown)(xe)
ev(sml::String) = sml == "" ?  nothing : ev(parse_s(sml))


"Evaluate argument to their pre-existing definition in this module,
as in prior to using it in a function call. This would typically be
a unit like 'mm', or a function like 'pow'"
ev_existing(x) = x
function ev_existing(x::Symbol)
    @assert isdefined(@__MODULE__, x) " not yet defined here: $x"
    getfield(@__MODULE__, x)
end


has_no_units(v) = unit(v) == NoUnits
function has_no_units(v::AbstractArray)
    for u in unit.(v)
        u !== NoUnits && return false
    end
    true
end

is_dimension_compatible(u, v) = dimension(u) == dimension(v)
is_dimension_compatible(u, v::AbstractArray) = is_dimension_compatible(v, u)
function is_dimension_compatible(u::AbstractArray, v)
    dv = dimension(v)
    for dimu in dimension.(u)
        dimu !== dv && return false
    end
    true
end
function is_dimension_compatible(u::AbstractArray, v::AbstractArray)
    dimension.(u) == dimension.(v)
end




"String containing ML structured math-> XMLElement"
parse_s(s::String) = """<wr xmlns:ml="http://0">""" * s * "</wr>" |> parse_string |> root |> child_elements |> first
