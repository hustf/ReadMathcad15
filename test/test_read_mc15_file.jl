using Test
using ReadMathcad15
using ReadMathcad15.read_mc15_file
import .read_mc15_file:  root_node, regions, regions_root
import .read_mc15_file:  id, ids
import .read_mc15_file:  has_math_definition, has_id
import .read_mc15_file:  math_definition_regions, math_definition_elements
import .read_mc15_file:  math_definition_elements_with_id
import .read_mc15_file:  math_definition_elements_with_id_result
import .read_mc15_file:  math_definition_elements_with_id_apply
import .read_mc15_file:  has_result, has_apply, has_unitoverride, has_math_definition
import .read_mc15_file:  regions, math_def_element
import .read_mc15_file:  child_elements_ignore_provenance
import .read_mc15_file:  count_consecutive
import .read_mc15_file:  reduce_tab_indent
import .read_mc15_file:  last_child_element
import .read_mc15_file:  _string
import .read_mc15_file: find_first_element
fnam = "public_files/sinal_rice.xmcd"
fnam = "public_files/snelast.xmcd"
fnam = "public_files/Vindlast.xmcd"
fnam = "Beamcheck.xmcd"
rno, xdoc = root_node(fnam);
regroot = regions_root(rno);
allregions = regions(regroot);
mathdefinitionregions = math_definition_regions(regroot);
@test length(mathdefinitionregions) < length(allregions)

@testset "Ignore provenance and related elements" begin
    for i = 1:length(mathdefinitionregions)
        mre = mathdefinitionregions[i]
        if has_math_definition(mre)
            try
                me = math_def_element(mre)
            catch err
                @show i
                rethrow(err)
            end
        end
    end
    @test true
end

mre = mathdefinitionregions[min(55, length(mathdefinitionregions))]
mma = mre |> child_elements_ignore_provenance |> first

mrech = mma |> child_elements_ignore_provenance

mathdefinitionelements = math_definition_elements(regroot);
@test length(mathdefinitionelements) == length(mathdefinitionregions)
mathdefinitionelementswithid = math_definition_elements_with_id(regroot);
@test length(mathdefinitionelements) >= length(mathdefinitionelementswithid )
notvariabledefinition = filter(!has_id, math_definition_elements(regroot));
length(notvariabledefinition)
identifiers = ids(regroot);
parentregionofvariable = parentregion_of_variable(regroot);
defdic = definition_of_variable(regroot)
@test length(parentregionofvariable) == length(defdic)
id_result = math_definition_elements_with_id_result(regroot);
id_apply = math_definition_elements_with_id_apply(regroot);
length(id_apply)
length(id_result)
length(defdic)
bothresultandapply = intersect(keys(id_apply),keys(id_result));
length(bothresultandapply)
resultofvariable = result_of_variable(regroot);
length(resultofvariable)
unitoverrideofvariable = unitoverride_of_variable(regroot);
length(unitoverrideofvariable)
applyofvariable = apply_of_variable(regroot);
length(applyofvariable)
definitionofvariable = definition_of_variable(regroot);
length(definitionofvariable)
@test length(applyofvariable) == length(apply_of_variable(fnam))
@test length(unitoverrideofvariable) == length(unitoverride_of_variable(fnam))
@test length(resultofvariable) == length(result_of_variable(fnam))
@test length(definitionofvariable) == length(definition_of_variable(fnam))
@test length(parentregionofvariable) == length(parentregion_of_variable(fnam))

@test count_consecutive(c -> (c=='\t'), "\t\t \t\t\t etc") == 3

@test begin
    lins = "l1\n\t\t\t\t\tl2\n\t\t\t\t\t\tl3\n\t\t\t\t\tl4\n"
    reduce_tab_indent(lins, 5) == "l1\nl2\n\tl3\nl4\n"
end
mre = mathdefinitionregions[min(55, length(mathdefinitionregions))]




@testset "A sequenced list of useable symbols" begin
    pairs = assignable_pairs(fnam)
    @test pairs isa Vector{Pair{Symbol, String}}
    @test length(pairs) > 0
end
@test typeof(last_child_element(regroot)) == read_mc15_file.LightXML.XMLElement

@test _string(regroot) isa String

@test find_first_element(regroot, "a/b/c") == nothing
@test find_first_element(rno, "worksheet") !== nothing
@test find_first_element(rno, "worksheet/notexist") == nothing
@test find_first_element(rno, "worksheet/settings/calculation/units/currentUnitSystem") isa read_mc15_file.LightXML.XMLElement


@test begin
    s = _string(find_first_element(rno, "worksheet/settings/calculation/units/currentUnitSystem"))
    s == """<currentUnitSystem name="si" customized="false"/>"""
end


 #worksheet settings calculation units  currentUnitSystem attribute name="si"