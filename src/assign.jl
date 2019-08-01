"""
Define variable(s) based on dictionary
# Example
```julia-repl
julia> using ReadMathcad15

julia @assign "myfile.xmcd" x y
julia> @show x y;
x = 22
y = 23
```
"""
macro assign(fnam, vars...)    
    expr = Expr(:block)
    push!(expr.args, Expr(:(=), :myfnam, esc(:($fnam))))
    push!(expr.args, quote
        assign_symbols = assignable_pairs(myfnam)
        @assert length(assign_symbols) > 0
        vardic = Dict{Symbol, String}(assign_symbols)
    end)
    for var in vars
        ex_i = esc(Meta.quot(var))
        ex_inner = Expr(:(=), esc(var), :(ev(get(vardic, $ex_i, "NA"))))
        push!(expr.args, :(const global $ex_inner))
        push!(expr.args, :(print("\t", $ex_i, " = ")))
        push!(expr.args, esc(:(println($var))))
    end
    push!(expr.args, :(nothing))
    expr
end
