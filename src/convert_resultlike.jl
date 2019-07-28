module interpretMathML

export XMLElement
export assign



"""
Define variable(s) based on dictionary
# Example
```julia-repl
julia> vardic=Dict(:x => 22, :y => 23, :z=>53)
Dict{Symbol,Int64} with 2 entries:
  :y => 23
  :x => 22
@assign vardic x y;
julia> @show x y;
x = 22
y = 23
```
"""
macro assign(dic, vars...)
    expr = Expr(:block)
    for var in vars
        ex_i = esc(Meta.quot(var))
        ex_i2 = esc(dic)
        ex_inner = Expr(:(=), esc(var), :(get($ex_i2, $ex_i, "NA")))
        ex = quote
            const global $ex_inner
        end
        push!(expr.args, ex)
    end
    push!(expr.args, :(nothing))
    expr
end

end