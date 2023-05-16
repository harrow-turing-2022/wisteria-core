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


_n = 3
_δ = 0.3
_ρ = 0.5
_θ = NaN
_levels = Inf


function init(source::Int32, deg1s::Set{Int32})
    drainage = Dict{Int32, Float64}(collect(deg1s) .=> 0)
    for v in [fwg.links[source]; bwg.links[source]]
        (v in deg1s) && (drainage[v] += 1)
    end
    return drainage
end


function step(prev::Dict{Int32, Float64}, deg1s::Set{Int32})
    next = Dict{Int32, Float64}(collect(deg1s) .=> 0)
    for i in deg1s
        unit::Float64 = prev[i] / length(fwg.links[i])
        for v in fwg.links[i]
            (v in deg1s) && (next[v] += unit)
        end
    end
    return next
end


function explore!(
        source::Integer, levels::Number, direction::Function;
        prereqs::Dict{Int32, Vector{Int32}}=Dict{Int32, Vector{Int32}}(),
        explored::Set{Int32}=Set{Int32}(),
        n::Integer=_n, δ::Float64=_δ, ρ::Float64=_ρ, θ::Float64=_θ
    )

    κpsrc = runfunc(κ_prime, source)
    (direction == +) && (compFn = >)
    (direction == -) && (compFn = <)
    isnan(θ) && ( θ = (direction == -) ? 0.3 : 25.0 )

    (levels == 0 || (levels == Inf && compFn(κpsrc, θ))) && (return prereqs)

    push!(explored, source)
    deg1s = Set(union(fwg.links[source], bwg.links[source]))
    drainage = init(source, deg1s)

    for _ = 1:n
        drainage = step(drainage, deg1s)
    end

    idxThresh = κpsrc * direction(1, δ)
    ids = Int32[i for i in deg1s if compFn(runfunc(κ_prime, i), idxThresh)]
    acc = Float64[drainage[i] for i in ids]

    (length(ids) == 0) && (return prereqs)
    
    accThresh = maximum(acc) * (1 - ρ)

    list = Int32[]
    vals = Float64[]
    for (e, i) in enumerate(ids)
        if acc[e] > accThresh
            push!(vals, acc[e])
            push!(list, i)
        end
    end

    (length(list) == 0) && (return prereqs)

    prereqs[source] = list[sortperm(vals; rev=true)] # Start learning from biggest drainage - the most important concepts
    toExplore = setdiff(prereqs[source], explored)
    union!(explored, toExplore)

    for i in toExplore
        explore!(i, levels-1, direction; prereqs=prereqs, explored=explored, δ=δ, ρ=ρ, θ=θ)
    end
    
    return prereqs
end


function _nestedStringify(id, prereqs; prefix="", ret="", root=0, done=Set{Int32})
    (root == 0) && (root = id)
    if haskey(prereqs, id)
        for e = 1:length(prereqs[id])-1
            i = prereqs[id][e]
            if i in done
                (i != root) && (ret *= "$(prefix)├── ** $(fwg.pm.id2title[i]) **\n")
            else
                push!(done, i)
                ret *= "$(prefix)├── $(fwg.pm.id2title[i])\n"
                ret = _nestedStringify(i, prereqs; prefix="$(prefix)│   ", ret=ret, root=root, done=done)
            end
        end
        i = prereqs[id][end]
        if i in done
            (i != root) && (ret *= "$(prefix)└── ** $(fwg.pm.id2title[i]) **\n")
        else
            push!(done, i)
            ret *= "$(prefix)└── $(fwg.pm.id2title[i])\n"
            ret = _nestedStringify(i, prereqs; prefix="$(prefix)    ", ret=ret, root=root, done)
        end
    end
    return ret
end


function stringifyReqs(title::String, direction::Function; levels=_levels, n=_n, δ=_δ, ρ=_ρ, θ=_θ, md=false)
    titleID = fwg.pm.title2id[title]

    prereqs = explore!(titleID, levels, direction; n=n, δ=δ, ρ=ρ, θ=θ)

    ret::String = ""
    md && (ret *= "```\n")
    ret *= "$(title) ($(direction)) [n=$(n), δ=$(δ), ρ=$(ρ), θ=$(θ), levels=$(levels)]\n"
    ret *= _nestedStringify(titleID, prereqs; done=Set(titleID))
    md && (ret *= "```\n\n---\n\n")
    return ret
end


function screen(title::String; ns=1:6, deltas=0.1:0.1:0.6, rhos=0.1:0.1:0.6, levels=1:3)
    fname = "output/pathway_$(title)_planning.md"
    checkfile(fname)

    open(fname, "a") do f

        println(title)
        write(f, "# $(title)\n")

        for direction in ( - , + )

            write(f, "## $(title) ($(direction))\n")

            write(f, "### $(title) ($(direction)) `Default`\n")
            write(f, stringifyReqs(title, direction; md=true))
            print(".")

            write(f, "### $(title) ($(direction)) `n`\n")
            for i in ns
                write(f, stringifyReqs(title, direction; n=i, levels=1, md=true))
            end
            print(".")

            write(f, "### $(title) ($(direction)) `δ`\n")
            for i in deltas
                write(f, stringifyReqs(title, direction; δ=i, levels=1, md=true))
            end
            print(".")

            write(f, "### $(title) ($(direction)) `ρ`\n")
            for i in rhos
                write(f, stringifyReqs(title, direction; ρ=i, levels=1, md=true))
            end
            print(".")

            write(f, "### $(title) ($(direction)) `levels`\n")
            for i in levels
                write(f, stringifyReqs(title, direction; levels=i, md=true))
            end
            println(".")
        end
    end
end


screen("Meiosis"; ns=1:20)
screen("Climate_change")
screen("Newton's_laws_of_motion")
screen("Parallel_postulate")
screen("Public-key_cryptography")

screen("Special_relativity")
screen("Artificial_intelligence")
screen("Calculus")
screen("Linear_algebra")
screen("Wikipedia")
screen("Julia_(programming_language)")
screen("Impressionism")
screen("Tardigrade")
screen("Virgil")

print(stringifyReqs("Causality", -; n=3, δ=0.3, ρ=0.35, levels=_levels))
print(stringifyReqs("Causality", +; n=3, δ=0.3, ρ=0.35, levels=_levels))
