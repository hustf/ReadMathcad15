module ReadMathcad15
export assignable_pairs,
    ev,
    unitoverride_of_variable, 
    apply_of_variable,
    result_of_variable, 
    parentregion_of_variable,
    definition_of_variable,
    ev

using LightXML
using MechanicalUnits
@import_expand ~V ~W ~A mol
global const deg = °
global const mole = mol
include("read_mc15_file.jl")
using .read_mc15_file
include("evaluate_mathcad15.jl")
#include("convert_resultlike.jl")


function __init__()
    # Refer read_mc15_file -> validateunits and evaluate_mathcad15.ev_unitedValue
    # Luminance (candela) would crash with a julia function, 

    preferunits(m, kg, s, A, K, mol)
end
end