#=
Copyright (C) 2023  Yiding Song

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
=#


using("common.jl")


function explore!(
        source::Integer, levels::Number, direction::Function;
        prereqs::Dict{Int32, Vector{Int32}}=Dict{Int32, Vector{Int32}}(),
        explored::Set{Int32}=Set{Int32}(),
        δ::Float64=0.4, ρ::Float64=0.4, θ::Float64=NaN
    )

    κpsrc = runfunc(κ_prime, source)
    (direction == +) && (compFn = >)
    (direction == -) && (compFn = <)
    if isnan(θ)
        θ = (direction == -) ? 0.3 : 25.0
    end

    if levels == 0
        return prereqs
    elseif levels == Inf && compFn(κpsrc, θ)
        return prereqs
    end

    push!(explored, source)
    deg1s = union(fwg.links[source], bwg.links[source])

    if length(deg1s) > 1e+5
        drainage = Float64[0.0 for _ = 1:fwg.pm.totalpages]
        drainage[fwg.links[source]] .+= 1
        drainage[bwg.links[source]] .+= 1
    else
        drainage = Dict{Int32, Float64}(i => 0 for i in deg1s)
        for v in fwg.links[source]
            drainage[v] += 1
        end
        for v in bwg.links[source]
            drainage[v] += 1
        end
    end

    for u in deg1s
        unit = drainage[u] / (length(fwg.links[u]) + length(bwg.links[u]))

        if length(deg1s) > 1e+5
            drainage[fwg.links[u]] .+= unit
            drainage[bwg.links[u]] .+= unit
        else
            for v in intersect(fwg.links[u], deg1s)
                drainage[v] += unit
            end
            for v in intersect(bwg.links[u], deg1s)
                drainage[v] += unit
            end
        end
    end

    idxThresh = κpsrc * direction(1, δ)

    ids = [
        i for i in deg1s
        if (i ∉ explored) && compFn(runfunc(κ_prime, i), idxThresh)
    ]
    acc = Float64[drainage[i] for i in ids]

    if length(ids) == 0
        return prereqs, acc, ids
    end
    
    accThresh = maximum(acc) * (1 - ρ)

    prereqs[source] = sort([i for (e, i) in enumerate(ids) if acc[e] > accThresh]) # Start learning from small κ'
    union!(explored, prereqs[source])

    for i in prereqs[source]
        explore!(i, levels-1, direction; prereqs=prereqs, explored=explored, δ=δ, ρ=ρ, θ=θ)
    end
    
    return prereqs, acc, ids
end


function _nestedPrint(id, prereqs, prefix)
    if haskey(prereqs, id)
        for e = 1:length(prereqs[id])-1
            i = prereqs[id][e]
            println("$(prefix)├── $(fwg.pm.id2title[i])")
            _nestedPrint(i, prereqs, "$(prefix)│   ")
        end
        i = prereqs[id][end]
        println("$(prefix)└── $(fwg.pm.id2title[i])")
        _nestedPrint(i, prereqs, "$(prefix)    ")
    end
end


function printReqs(title::String; direction=nothing, levels=Inf, δ=0.4, ρ=0.4, θ=NaN)
    titleID = fwg.pm.title2id[title]

    if direction === nothing
        κp = runfunc(κ_prime, titleID)
        if κp < 15 direction = +
        else direction = - end
    end

    prereqs, = explore!(titleID, levels, direction; δ=δ, ρ=ρ, θ=θ)
    println(fwg.pm.id2title[titleID])
    _nestedPrint(titleID, prereqs, "")
end


printReqs("Meiosis"; direction=+)
printReqs("Meiosis"; direction=-, levels=3)
printReqs("Meiosis"; direction=-)

printReqs("Special_relativity"; direction=+, levels=2)
printReqs("Meiosis"; direction=-, levels=3)
