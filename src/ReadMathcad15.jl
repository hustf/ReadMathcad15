module ReadMcd

export unitoverride_of_variable, apply_of_variable, result_of_variable, parentregion_of_variable

using LightXML


# 
#  Public API
# 

"""
Return a dictionary of id symbol => math definition element.
Parents are the containing math definitions.
"""
function definition_of_variable(filename::String) 
    filename |> root_node |> regroot |> definition_of_variable
end
function definition_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	mathdefinitions = math_definition_elements_with_id(xe)
	for defe in mathdefinitions
	   push!(di, id(id_element(defe)) => defe)
	end
	di
end


"""
Return a dictionary of id symbol => result xml.
Symbols are defined by an 'apply' and / or 'result' element.
"""
function result_of_variable(filename::String) 
    filename |> root_node |> regroot |> result_of_variable
end
function result_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	mathdefinitions = math_definition_elements_with_id(xe)
	for defe in mathdefinitions
	    if has_result(defe)
		   eval = find_element(defe, "eval")
		   res = find_element(eval, "result")
	       push!(di, id(id_element(defe)) => res)
	    end
	end
	di
end

"""
Return a dictionary of id symbol => result xml.
Symbols are defined by an 'apply' and / or 'result' element.
"""
function apply_of_variable(filename::String) 
    filename |> root_node |> regroot |> apply_of_variable
end
function apply_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	mathdefinitions = math_definition_elements_with_id(xe)
	for defe in mathdefinitions
	    if has_apply(defe)
		   eval = find_element(defe, "eval")
		   res = find_element(eval, "apply")
	       push!(di, id(id_element(defe)) => res)
	    end
	end
	di
end

"""
Return a dictionary of id symbol => unit override xml.
The unit override, if present, represents a conversion for presentation.
"""
function unitoverride_of_variable(filename::String) 
    filename |> root_node |> regroot |> unitoverride_of_variable
end
function unitoverride_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	mathdefinitions = math_definition_elements_with_id(xe)
	for defe in mathdefinitions
	    if has_unitoverride(defe)		
		   eval = find_element(defe, "eval")
		   res = find_element(eval, "unitOverride")
	       push!(di, id(id_element(defe)) => res)
	    end
	end
	di
end

"""
Return a dictionary of id symbol => parent region.
Parents are the containing regions.
"""
function parentregion_of_variable(filename::String) 
    filename |> root_node |> regroot |> parentregion_of_variable
end
function parentregion_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	regions = math_definition_regions(xe)
	for reg in regions
	    defe = math_def_element(reg)
		if has_id(defe)
		   thisid = id(id_element(defe))
	       push!(di,  thisid => reg)
		end
	end
	di
end

#
# Internal functions
#




"Return the root node of a Mathcad file."
function root_node(fnam::String)
    if !isfile(fnam)
        error("File does not exist")
    end
    xdoc = parse_file(fnam)
    xroot = root(xdoc)  # an instance of andXMLElement
end

"Given a root node, return all regions"
function regions(xroot::XMLElement)
    regions = []
    # traverse all its child nodes 
    for c in child_nodes(xroot)  # c is an instance of XMLNode
        if is_elementnode(c)
            e = XMLElement(c)
            if name(e) == "region"
                push!(regions, e)
            end
        end
    end
    return regions
end

"Return the 'regions' root element"
function regions_root(xroot::XMLElement)
    # traverse all child nodes and return the element with name 'regions'
    for c in child_nodes(xroot)  # c is an instance of XMLNode
        if is_elementnode(c)
            e = XMLElement(c)  # this makes an XMLElement instance
            if name(e) == "regions"
                return e
            end
        end
    end
    error("Could not find 'regions'")
end

"Returns true if the element contains a variable definition"
function has_math_definition(xe::XMLElement)
    for che in child_elements(xe)
        if name(che) == "math"
            for ce in child_elements(che)
                if name(ce) == "define"
                    return true
                end
            end
        end
    end
    false
end

"Returns true if the definition element contains a variable definition"
function has_id(xde::XMLElement)
    if name(xde) != "define"
        error("input must be a definition element")
    end
    for che in child_elements(xde)
        if name(che) == "id"
            # Check that we can translate the name
            na = id(che)
            return true
        end
    end
    return false
end

"Returns the definition element which is a child of the region xe"
function math_def_element(xe::XMLElement)
    if name(xe) != "region"
        error("input is not a region element")
    end
    # We're just assuming there can be only one definition in xe". So check!
    defs = []
    for che in child_elements(xe)
        if name(che) == "math"
            for ce in child_elements(che)
                if name(ce) == "define"
                    push!(defs, ce)
                end
            end
        end
    end
    if length(defs) != 1
        error("unexpected: several definitions in this region")
    else
        return defs[1]
    end
end

"Returns the id element within this definition element."
function id_element(xe::XMLElement)
    # We're intending to apply this on definition elements. But check
    if name(xe) != "define"
        error("input is not a definition element")
    end
    # We're also checking against multiple ids here.
    ids = XMLElement[]
    for che in child_elements(xe)
        if name(che) == "id"
            push!(ids, che)
        end
    end
    if length(ids) != 1
        error("unexpected: Several ids in this definition.")
    else
        return ids[1]
    end
end

"""
Returns a Julia symbol.
Subscripts are represented by '_'
"""
function id(idel::XMLElement)
	if name(idel) != "id"
		error("input is not an id element")
	end
    if has_children(idel)
        sub = attribute(idel, "subscript")
        textnode = first(child_nodes(idel))
        if is_textnode(textnode)
            if sub == nothing
                na = Symbol(content(textnode))
            else
                na = Symbol(content(textnode), "_" *replace(sub, "." => "_"))
            end
        end
    else
        error("error parsing id name")
    end
    na
end



"Returns true if the definition element contains a result"
function has_result(xde::XMLElement)
    if name(xde) != "define"
        error("input must be a definition element")
    end
    for che in child_elements(xde)
        if name(che) == "eval"
			return _has_result(che)
        end
    end
    return false
end


"Returns true if the definition element contains an apply element"
function has_apply(xde::XMLElement)
    if name(xde) != "define"
        error("input must be a definition element")
    end
    for che in child_elements(xde)
        if name(che) == "eval"
			return _has_apply(che)
        end
    end
    return false
end
"Returns true if the definition element contains a unit override element"
function has_unitoverride(xde::XMLElement)
    if name(xde) != "define"
        error("input must be a definition element")
    end
    for che in child_elements(xde)
        if name(che) == "eval"
			return _has_unitoverride(che)
        end
    end
    return false
end

"Returns true if the eval element contains a result"
function _has_result(xde::XMLElement)
    if name(xde) != "eval"
        error("input must be an eval element")
    end
    for che in child_elements(xde)
        if name(che) == "result"
			return true
        end
    end
    return false
end

"Returns true if the eval element contains a formula to apply"
function _has_apply(xde::XMLElement)
    if name(xde) != "eval"
        error("input must be an eval element")
    end
    for che in child_elements(xde)
        if name(che) == "apply"
			return true
        end
    end
    return false
end

"Returns true if the eval element contains a unit override"
function _has_unitoverride(xde::XMLElement)
    if name(xde) != "eval"
        error("input must be an eval element")
    end
    for che in child_elements(xde)
        if name(che) == "unitOverride"
			return true
        end
    end
    return false
end


"Return contained region(s) with math definitions, in sequence."
math_definition_regions(xe::XMLElement) = filter(has_math_definition, regions(xe))

"Return contained math definition element(s) which are part of regions, in sequence."
math_definition_elements(xe::XMLElement) = math_def_element.(math_definition_regions(xe))

"Return contained math definition elements(s) with an identifier, in sequence."
math_definition_elements_with_id(xe::XMLElement) = filter(has_id, math_definition_elements(xe))

"Return contained variable ids, in sequence"
ids(xe::XMLElement) = id.(id_element.(math_definition_elements_with_id(xe)))

"Return contained math definition elements(s) with an identifier and a stored result, in sequence."
math_definition_elements_with_id_result(xe::XMLElement) = filter(has_result, math_definition_elements_with_id(xe))

"Return contained math definition elements(s) with an identifier and a stored result, in sequence."
math_definition_elements_with_id_apply(xe::XMLElement) = filter(has_apply, math_definition_elements_with_id(xe))








#=
    If the remainder of the script does not use the document or any of its children,
    you can call free here to deallocate the memory. The memory will only get
    deallocated by calling free or by exiting julia -- i.e., the memory allocated by
    libxml2 will not get freed when the julia variable wrapping it goes out of
    scope.
    #
    free(xdoc)
=#






end