push!(LOAD_PATH, @__DIR__);
using Revise
using ReadMcd
import ReadMcd:  assign
import ReadMcd:  readvars, root_node, regions, regions_root, math_definition_element
import ReadMcd:  id, ids
import ReadMcd:  has_math_definition, has_id
import ReadMcd:  math_definition_regions, math_definition_elements
import ReadMcd:  math_definition_elements_with_id
import ReadMcd:  math_definition_elements_with_id_result
import ReadMcd:  math_definition_elements_with_id_apply
import ReadMcd:  parentregion_of_variable_definition
import ReadMcd:  definition_of_variables
import ReadMcd:  has_result, has_apply, has_unitoverride

fnam = "Beamcheck.xmcd"
rno = root_node(fnam);
regroot = regions_root(rno);
allregions = ReadMcd.regions(regroot);
mathdefinitionregions = math_definition_regions(regroot);
length(mathdefinitionregions) < length(allregions)
mathdefinitionelements = math_definition_elements(regroot);
length(mathdefinitionelements) == length(mathdefinitionregions)
mathdefinitionelementswithid = math_definition_elements_with_id(regroot);
length(mathdefinitionelements) > length(mathdefinitionelementswithid )
notvariabledefinition = filter(!has_id, math_definition_elements(regroot));
identifiers = ids(regroot);
regiondic = parentregion_of_variable_definition(regroot)
defdic = definition_of_variables(regroot)
length(regiondic) == length(defdic)
id_result = math_definition_elements_with_id_result(regroot);
id_apply = math_definition_elements_with_id_apply(regroot);
length(id_apply)
length(id_result)
length(defdic)
bothresultandapply = intersect(keys(id_apply),keys(id_result));
length(bothresultandapply)


resultofvariables = result_of_variables(regroot);
length(resultofvariables)
unitoverrideofvariables = unitoverride_of_variables(regroot);
length(unitoverrideofvariables)
applyofvariables = apply_of_variables(regroot);
length(applyofvariables)