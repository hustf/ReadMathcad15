"""
Make dictionaries of variable symbol => XML ML strings.

Mathcad variable symbols are converted to Julia equivalents thus:
   Mathcad subscript => '_'
   Period '.' => '_'
   Mathcad namespace (font style) => ignored.

"""
module read_mc15_file

#=
 Note / TODO:
 The function find_first_element was added after exploring the 
 file format. 
 It should be possible to restructure and simplify the code to using that.
 Another approach to simplifying this code is using EzXML.jl.
=#


export print_symbols_from,
    symbols_from,
    assignable_pairs,
    unitoverride_of_variable, 
    apply_of_variable,
    result_of_variable, 
    parentregion_of_variable,
    definition_of_variable,
    child_elements_ignore_provenance


using ..LightXML

# 
#  Public API
# 
"Print a list of available symbols from the Mathcad file, suitable for copying to @assign filename ..."
function print_symbols_from(filename)
    sms = string.(symbols_from(filename))
    colwidth = maximum(textwidth.(sms)) + 2
    _, co = displaysize(stdout)
    cols = div(co, colwidth)
    for i in 1:length(sms)
        print(rpad(sms[i], colwidth));
        curpos = (((i-1) % cols ) + 1) * colwidth
        remaining = co - curpos
        if remaining < colwidth
           print(stdout, repeat(' ', remaining))
        end
    end
end

"""
Symbols which are available for importing from the Mathcad file
```Julia-repl
Julia> using ReadMathcad15
Julia> fnam = "myfile.xmcd"
Julia> @assign fnam symbols_from(fnam)...
```
The symbols are returned in a vector, following the sequence in which they are defined.
"""
function symbols_from(filename)
    rootnode, xdoc = filename |> root_node
    defregions = rootnode |> regions_root |> math_definition_elements_with_id_result
    symbols = defregions .|> id_element .|> id
    free(xdoc)
    symbols    
end

"""
Return a vector of pairs, symbols => eval chunk in xml string format.
The vector contains only the pairs which can be
evaluated without following references to other chuncks,
i.e. mostly direct value assignments or 'file memoized' results.
"""
function assignable_pairs(filename::String)::Vector{Pair{Symbol, String}}
    rootnode, xdoc = filename |> root_node
    containingdefinitions = rootnode |> regions_root |> math_definition_elements_with_id_result
    pairs = Vector{Pair{Symbol, String}}()
    for defreg in containingdefinitions
        symid = defreg |> id_element |> id
        defchis = child_elements_ignore_provenance(defreg)
        @assert length(defchis) == 2 _string(defreg)
        @assert name(defchis[2]) == "eval"
        va = _string(defchis[2])
        push!(pairs, symid => va)
    end
    free(xdoc)
    pairs
end



"""
Return a dictionary of id symbol => math definition element.
Parents are the containing math definitions.
"""
definition_of_variable(filename::String) = xml_of_variable(filename, definition_of_variable)::Dict{Symbol, String}

"""
Return a dictionary of id symbol => result xml.
Symbols are defined by an 'apply' and / or 'result' element.
"""
result_of_variable(filename::String) = xml_of_variable(filename, result_of_variable)::Dict{Symbol, String}

"""
Return a dictionary of id symbol => result xml.
Symbols are defined by an 'apply' and / or 'result' element.
"""
apply_of_variable(filename::String) = xml_of_variable(filename, apply_of_variable)::Dict{Symbol, String}

"""
Return a dictionary of id symbol => unit override xml.
The unit override, if present, represents a conversion for presentation.
"""
unitoverride_of_variable(filename::String) = xml_of_variable(filename, unitoverride_of_variable)::Dict{Symbol, String}

"""
Return a dictionary of id symbol => parent region.
Parents are the containing regions.
"""
parentregion_of_variable(filename::String) = xml_of_variable(filename, parentregion_of_variable)::Dict{Symbol, String}




"""
A 'provenance' element provides (usually unknown, uninteresting, and inaccessible to the user) historic metadata. 
It encapsulates single elements, e.g. 'define', 'id', 'apply'.

<provenance>
    <originRef>
        <hash/>
    </originRef>
    <parentRef>
        <hash/>
    </parentRef>
    <comment/>
    <originComment/>
    <contentHash>
    </contentHash>
    <ENCAPSULATED></ENCAPSULATED>
</provenance>

`child_elements_ignore_provenance` could be an 
iterator, but a vector can be iterated over too. 
"""
function child_elements_ignore_provenance(xe::XMLElement)
    ve = Vector{XMLElement}()
    for x in child_elements(xe)
        name(x) ∈ ["originRef", "parentRef", "originComment", "contentHash"] && continue
        if name(x) == "provenance"
            push!(ve, last_child_element(x))
        else
            push!(ve, x)
        end
    end
    ve
end


#
# Internal functions
#

"""
Return a dictionary where keys are Mathcad variables,
and values are xml elements in some relation to that variable 
definition. 
"""
function xml_of_variable(filename::String, foo::Function)::Dict{Symbol, String}
    rootnode, xdoc = filename |> root_node 
    dic_symbol_xmlelement = rootnode |> regions_root |> foo
    dic_symbol_string = Dict{Symbol, String}()
    # Convert Dict{Symbol, XMLElement} to Dict{Symbol, String}
    # Also reduce the tab indent for readability. Values are often deeply nested.
    for (sy, xe) in dic_symbol_xmlelement
        push!(dic_symbol_string, sy => _string(xe))
    end
    # The external library does not free up memory automatically
    free(xdoc)
    dic_symbol_string
end

function definition_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	mathdefinitions = math_definition_elements_with_id(xe)
	for defe in mathdefinitions
	   push!(di, id(id_element(defe)) => defe)
	end
	di
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

function parentregion_of_variable(xe::XMLElement)
	di = Dict{Symbol, XMLElement}()
	regions = math_definition_regions(xe)
	for reg in regions
	    defe = math_def_element(reg)
        if has_id(defe)
            thisid = try 
                id(id_element(defe))
            catch
                @show reg
                @show defe
                throw(" could not find the id contained in defe ")
            end
	        push!(di,  thisid => reg)
		end
	end
	di
end


"Return the root node of a Mathcad file, and also a reference to the document."
function root_node(fnam::String)
    @assert isfile(fnam) "$fnam not found in current directory $(pwd())"
    xdoc = parse_file(fnam)
    @assert validateunits(xdoc)
    root(xdoc), xdoc
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
    for che in child_elements_ignore_provenance(xe)
        if name(che) == "math"
            for ce in child_elements_ignore_provenance(che)
                if name(ce) == "define"
                    return true
                end
            end
        end
    end
    false
end


"Returns true if the definition element contains one variable definition"
function has_id(xde::XMLElement)
    @assert name(xde) == "define" " not a define element: $xde"
    count = 0    
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "id"
            # Check that we can translate the name
            na = id(che)
            count += 1
        end
    end
    return count == 1
end

"Returns the definition element which is a child of the region xe"
function math_def_element(xe::XMLElement)
    @assert name(xe) == "region" " not a region element: $xe"
    # We're just assuming there can be only one definition in xe". So check!
    defs = []
    for che in child_elements_ignore_provenance(xe)
        if name(che) == "math"
            for ce in child_elements_ignore_provenance(che)
                if name(ce) == "define"
                    push!(defs, ce)
                end
            end
        end
    end
    @assert length(defs) == 1 " several definitions in this element $xe"
    defs[1]
end

"Returns the id element within this definition element."
function id_element(xe::XMLElement)
    @assert name(xe) == "define" " not a define element: $xe"
    # We're also checking against multiple ids here.
    ids = XMLElement[]
    for che in child_elements_ignore_provenance(xe)
        if name(che) == "id"
            push!(ids, che)
        end
    end
    @assert length(ids) == 1 " several ids in this element $xe"
    return ids[1]
end

"""
Returns a Julia symbol.
Subscripts are represented by '_'
"""
function id(idel::XMLElement)
    @assert name(idel) == "id" " not an id element $idel"
    @assert has_children(idel) " no children $idel" 
    textnode = first(child_nodes(idel))
    @assert is_textnode(textnode) " first child is not a textnode $idel"
    sub = attribute(idel, "subscript")
    if sub == nothing
        na = Symbol(content(textnode))
    else
        na = Symbol(content(textnode), "_" *replace(sub, "." => "_"))
    end
    na
end


"Returns true if the definition element contains a result"
function has_result(xde::XMLElement)
    @assert name(xde) == "define" " not a definition element $xde"
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "eval"
			return _has_result(che)
        end
    end
    return false
end


"Returns true if the definition element contains an apply element"
function has_apply(xde::XMLElement)
    @assert name(xde) == "define" " not a definition element $xde"
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "eval"
			return _has_apply(che)
        end
    end
    return false
end
"Returns true if the definition element contains a unit override element"
function has_unitoverride(xde::XMLElement)
    @assert name(xde) == "define" " not a definition element $xde"
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "eval"
			return _has_unitoverride(che)
        end
    end
    return false
end

"Returns true if the eval element contains a result"
function _has_result(xde::XMLElement)
    @assert name(xde) == "eval" " not an eval element $xde"
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "result"
			return true
        end
    end
    return false
end

"Returns true if the eval element contains a formula to apply"
function _has_apply(xde::XMLElement)
    @assert name(xde) == "eval" " not an eval element $xde"
    for che in child_elements_ignore_provenance(xde)
        if name(che) == "apply"
			return true
        end
    end
    return false
end

"Returns true if the eval element contains a unit override"
function _has_unitoverride(xde::XMLElement)
    @assert name(xde) == "eval" " not an eval element $xde"
    for che in child_elements_ignore_provenance(xde)
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



"
'reduce_tab_indent(s, level)'
Remove the 'level' number of consecutive tabs. 
Improve readability of extracts from deeply nested XML.
"
function reduce_tab_indent(s, level)
    lines = split(s, "\n")
    dr = repeat('\t', level)
    shorterlines = map(lines) do l
        replace(l, dr  => "", count =1)
    end
    join(shorterlines, '\n')
end

"Find the indent level of an xml chunck indirectly, by printing"
function find_level(lines)
    candidates = filter(n -> n > 0, count_consecutive.(i -> (i=='\t'), lines))
    length(candidates) == 0 && return 0
    minimum(candidates)
end
find_level(s::AbstractString) = find_level(split(string(s), '\n'))
find_level(xe::XMLElement) = find_level(string(xe))

"""
Used internally for making deeply nested xml elements more readable when output as string
    # Examples
    ```julia-repl
    julia> count_consecutive(c -> (c=='\t'), "\t\t \t\t\t etc")
    3
    ```
"""
function count_consecutive(pred, itr)
    n = 0
    nm = 0
    for x in itr
        if pred(x)::Bool
            n+=1
        else
            if n > nm
                nm = n
                n = 0
            end
        end
    end
    return max(n, nm)
end


function last_child_element(xe::XMLElement)
    lc = xe
    for ch in child_elements(xe)
        lc = ch
    end
    lc
end

"""
For printing recursively, we can't start every line at the right margin.
Note: libxml2 seems to have a 'level' input which we can't easily get to work.
We could depend on EzXML which has more functionality, but doesn't easily 
work on Windows.
"""
function _string(xe::XMLElement)
    level = find_level(xe)
    s = _string(xe.node, level = level)
    reduce_tab_indent(s, level)
end
_string(nd::XMLNode; level = 0) = repeat('\t', level) * string(nd)

"""
We only implement reading files where the units of XX in
  <unitedvalue > XX <unitMonomial> YY </unitMonomial> </unitedvalue>
are the base units of YY's dimensions (length, time etc.).

Mathcad defines the "si" list as:
  - length -> meter, 
  - mass -> kilogram, 
  - time -> second,
  - current -> ampere
  - temperature -> kelvin
  - luminance -> candeLa
  - number of substance -> mole
"""
function validateunits(xdoc)
    rno= root(xdoc)
    el = find_first_element(rno, "worksheet/settings/calculation/units/currentUnitSystem")
    el == nothing && error(" can't find currentUnitSystem")
    @assert attribute(el, "name") == "si"
    @assert attribute(el, "customized") == "false"
    true
end


"""
`find_first_element(xe::XMLElement, path::AbstractString)`

#Example
```julia-repl
julia> println(ex)
<a>
    ... 
    <ml:b>
       ...
        <provenance>
            <..>
            <c>
                <d>1</d>
                <d>2</d>
            </c>
        </provenance>
    <ml:b>
</a>

julia> find_first_element(ex, "a/b/c/d")
<d>1</d>
"""
function find_first_element(xe::XMLElement, path::AbstractString)
    path == "" && return nothing
    path == name(xe) && return xe
    this = path |> splitpath |> first
    this !== name(xe) && return nothing
    thislen = length(this)
    therest = path[(thislen+2):end]
    for c in child_elements_ignore_provenance(xe)
        matched = find_first_element(c, therest)
        matched != nothing && return matched
    end
    nothing
end



end