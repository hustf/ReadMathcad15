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

FOODIC = Dict{String, Function}()


function ev_eval(xe)
    @assert name(xe) == "eval"
    che = xe |> child_elements_ignore_provenance
    @assert name(che[1]) ∈ ["apply", "matrix"] " unknown structure\n $xe"
    if length(che) == 2
        @assert name(che[2]) == "result"
        ev(che[2])
    else
       @assert name(che[2]) == "unitOverride"
       @assert name(che[3]) == "result"
    end
    1
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
    @assert  che |> length == 2
    @assert che[1] |> name == "real"
    @assert che[2] |> name == "unitMonomial"
    unitm = ev(che[2])
    @show unitm
    @show ev(che[1])
    valu = ev(che[1])
    @show dimension(valu)
    dims = dimension(value)
    @show upreferred(dims)
    @show upreferred(dims...)
    @warn "TODO: UnitedValue is based on unit balancing. The number is in base units (usually m, etc.). The second is a unit conversion."
    @show upreferred( ᴸ )
    ev(che[1]) * ev(che[2])
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


function ev_unknown(xe)
    @info "No ev_$(name(xe))"
    1
end

"Evaluate structured ML math recursively"
ev(xe::XMLElement) = get(FOODIC, name(xe), ev_unknown)(xe)
ev(sml::String) = sml == "" ?  nothing : ev(parse_s(sml))

"String containing ML structured math-> XMLElement"
parse_s(s::String) = """<wr xmlns:ml="http://0">""" * s * "</wr>" |> parse_string |> root |> child_elements |> first
