using ReadMathcad15
using MechanicalUnits
fnam = "test/public_files/vindlast.xmcd"
fnam = "test/Beamcheck.xmcd"
syms = assignable_pairs(fnam);
pa = syms[31]
println(pa[1])
println(pa[2])
ev(syms[33][2])
for i = 1:length(syms)
    pa = syms[i]
    println(i, "\t", pa[1], " = ")
    println("\t", ev(syms[i][2]))    
end

syms[7][1]
syms[7][2] |> println

begin
    apply_s = apply_of_variable(fnam);
    unitoverride_s = unitoverride_of_variable(fnam);
    result_s = result_of_variable(fnam);
    definition_s = definition_of_variable(fnam);
    parentregion_s = parentregion_of_variable(fnam);
end;

"A union of keys in the dictionaries"
function allkeys(fnam)
    a = Set{Symbol}()
    push!(a, keys(apply_of_variable(fnam))...)
    push!(a, keys(unitoverride_of_variable(fnam))...)
    push!(a, keys(result_of_variable(fnam))...)
    push!(a, keys(definition_of_variable(fnam))...)
    push!(a, keys(parentregion_of_variable(fnam))...)
    a
end
"""
Return the xml data in file fnam assosiated with variable symbols, 
# Example
```Julia-repl
julia> inspect_strings(myfile.xmcd, :F_x)
```
Output is a tuple of strings. The last strings contain all the other elements.
"""
function inspect_strings(fnam::String, sy::Symbol)
    a = get(apply_of_variable(fnam), sy, "")
    u = get(unitoverride_of_variable(fnam), sy, "")
    r = get(result_of_variable(fnam), sy, "")
    d = get(definition_of_variable(fnam), sy, "")
    p = get(parentregion_of_variable(fnam), sy, "")
    return (a, u, r, d, p)
end

ev_a(sy::Symbol) =  get(apply_of_variable(fnam), sy, "") |> ev
ev_u(sy::Symbol) =  get(unitoverride_of_variable(fnam), sy, "") |> ev
ev_r(sy::Symbol) =  get(result_of_variable(fnam), sy, "") |> ev
ev_d(sy::Symbol) =  get(definition_of_variable(fnam), sy, "") |> ev
ev_p(sy::Symbol) =  get(parentregion_of_variable(fnam), sy, "") |> ev

ak = allkeys(fnam)

# First step is to properly evaluate 'results'
begin 
    for ke in keys(result_of_variable(fnam))
        resu = ev_r(ke)
        if resu == nothing
            println(ke)
        end
    end
end
resu = ev_r.(ak)

sy = :M_F3_t

(a, u, r, d, p) = inspect_strings(fnam, sy);
println(p)
println(a)
println(d)
println(r)
ev(r)
ev(d)
ev("")

allr_s = ak .|> geresult_s;

######### See if we correctly import and evaluate locally results

syms

resdic = Dict{Symbol, Any}()
for (ke, va) in result_s
    locres = ev(va)
    @assert locres !== nothing
    pa = ke => locres
    println(pa)
    push!(resdic, pa )
end
# Check 
:M_F3_t
:M_F2_t
:M_F3_r
:M_F1_r
#=
 There is nothing in the result object to indicate that it's incomplete.
 Which means we must do
  a) has it a result element within a definition?
  b) look at the parent, eval
  c) does eval have a unitOverride?
  d) Ignore the 'apply' element
  e) Evaluate 'result', assert the 'result' is unitless
  f) Multiply UnitOverride with the evaluated result. Asser What if result is not unitless?
=#

sy = :ϕ_pb
definition_s[sy] |> ev





definition_x(sy) = definition_s[sy] |> parse_s


s=apply_s[:b_0]
println(s)

unitoverride_x(sy) = unitoverride_s[sy] |> parse_s
result_x(sy) = result_s[sy] |> parse_s
parentregion_x(sy) = parentregion_s[sy] |> parse_s



pairs = map(keys(result_s)) do sy
    jres = 
end

syms = collect(keys(result_s))
res


allr_x = syms .|> result_x;
allres = allr_x .|> ev;

alldic = Dict{Symbol, Any}()
for (ke, va) in zip(syms, allres)
    push!(alldic, ke => va)
end
println.(zip(keys(alldic), values(alldic)));


alldic[:BE_σ_1]

result_x(:BE_σ_1)
result_x(:F_7)

r_x = result_x(:y_tie)
r_x |> ev

r_x = result_x(:A_c_t)
r_x |> ev

allr_x[1] |> ev
allr_x[1]


allr_x[2] |> ev
allr_x[2]

allr_x[3] |> ev
allr_x[3]

allr_x[4] |> ev
allr_x[4]

allr_x[5] |> ev
allr_x[5]

allr_x[6] |> ev
allr_x[6]

allr_x[7] |> ev
allr_x[7]

allr_x[8] |> ev
allr_x[8]



uexample = result_x(:y_tie) |> child_elements |> collect |> x-> getindex(x, 2)
uexample |> ev

reexample = result_x(:A_c_t)
reexample |> ev
ue = reexample |> child_elements |> collect |> x-> getindex(x, 2) |> getindex

applyroot(sy::Symbol) = get_elements_by_tagname(parse_string(definition_s[sy]) |> root, "apply")[1]


function head_op1_op2(sy::Symbol)
    print(" $sy ")
    ar = applyroot(sy)
    all = collect(child_elements(ar))
    length(all) != 3 && error("expected three elements: $sy")
    all[1], all[2], all[3]
end

head_op1_op2.(syms)

type MLExpr
    head
    op1
    op2
end

function MLExpr(xe::XMLElement)
end

head, op1, op2 = head_op1_op2(:w)
has_child
head
op1
op2
length(collect(child_elements(head))) == 0
length(collect(child_elements(op1))) == 0
length(collect(child_elements(op2))) == 0

expr = quote
        1*2
end
x = expr.args[2]
print(x)
typeof(x)
fieldnames(Expr)
x.head
x.args[1]

foodic= Dict{String, Symbol}()
push!(foodic, head)



using MechanicalUnits
unitdic = Dict{String, FreeUnits}()
push!(unitdic, "meter" => m)
push!(unitdic, "millimeter" => mm)
