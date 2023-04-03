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


using PyPlot
using ProgressBars
include("../wikigraph.jl")
include("exutils.jl")
include("indices.jl")


function expandBFS(wg, source; maxSeparation=Inf, verbose=false)
    s = 0
    r = 0
    explored = Int32[]
    separations = Int32[]
    frontier = Int32[t for (t, _) in wg.links[source]]

    while length(frontier) > 0 && s < maxSeparation
        newFrontier = Int32[]

        if verbose
            println("Expanding nodes of separation $(s)")
        end

        if verbose
            iter = ProgressBar(frontier)
        else
            iter = frontier
        end

        for id in iter
            if !(id in explored)
                push!(explored, id)
                push!(separations, s + 1)
                append!(newFrontier, [t for (t, _) in wg.links[id]])
            end
        end

        s += 1
        frontier = newFrontier
        r = length(newFrontier)
    end

    return (explored, separations, s, r)
end


function retrace(source, target, parents)
    ret = Int32[target]
    at = target

    while at != source
        at = parents[at]
        push!(ret, at)
    end

    return reverse(ret)
end


function connectBFS(wg, source, target; verbose=false)
    s = 1
    explored = Int32[]
    frontier = Int32[t for (t, _) in wg.links[source]]
    parents = Dict{Int32, Int32}(t => source for (t, _) in wg.links[source])

    if length(frontier) == 0
        return (Inf, [])
    end

    while length(frontier) > 0
        newFrontier = Int32[]

        if verbose
            println("Expanding nodes of separation $(s)")
        end

        if verbose
            iter = ProgressBar(frontier)
        else
            iter = frontier
        end

        for id in iter
            if id == target
                return (s, retrace(source, target, parents))
            elseif id ∉ explored
                push!(explored, id)
                for (t, _) in wg.links[id]
                    if t ∉ explored
                        push!(newFrontier, t)
                        if !haskey(parents, t)
                            parents[t] = id
                        end
                    end
                end
            end
        end

        s += 1
        frontier = newFrontier
    end

    return (Inf, [])
end


function race(wg, startTitle, endTitle; verbose=false)
    startID = wg.pm.title2id[startTitle]
    endID = wg.pm.title2id[endTitle]
    deg, path = connectBFS(wg, startID, endID, verbose=verbose)
    println("Degree $(deg) separation:")
    for id in path
        println(wg.pm.id2title[id])
    end
end


norm(x) = join([isletter(x[i]) ? x[i] : '_' for i in eachindex(x)])


function reachability(
        wg, source, rwg;
        maxSeparation=Inf, verbose=false, ysc="log", yfontsz=10, dpi=1000, color="forestgreen"
    )
    explored, separations, s, r = expandBFS(wg, source; maxSeparation=maxSeparation, verbose=verbose)
    numReached = length(explored)

    ttl = wg.pm.id2title[source]
    nzCount = length([i for i in countlinks(rwg)[1] if i != 0])

    println("At $(s) degrees of separation and wth $(r) remaining pages to expand, $(ttl) reaches:")
    println("| $(numReached) articles")
    println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia pages")
    println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia pages")

    hist(separations, bins=s, color=color)
    yscale(ysc)
    title("BFS expansion of $(ttl)")
    xlabel("Degree of separation")
    ylabel("Number of new pages reached", fontsize=yfontsz)
    savefig("output/bfs_$(norm(ttl))_deg$(s).png", dpi=dpi)
    cla()
end


fwg = loadwg("../graph/", "../data/enwiki-20230101-all-titles-in-ns0")
fwdCounts, fwdCountIDs = countlinks(fwg)
bwg = loadwg("../backgraph/", "../data/enwiki-20230101-all-titles-in-ns0")
bwdCounts, bwdCountIDs = countlinks(bwg)

philID = fwg.pm.title2id["Philosophy"]
reachability(fwg, philID, bwg; maxSeparation=1, verbose=true)
reachability(fwg, philID, bwg; maxSeparation=2, verbose=true)

reachability(bwg, philID, fwg; maxSeparation=1, verbose=true)
reachability(bwg, philID, fwg; maxSeparation=2, verbose=true)
reachability(bwg, philID, fwg; maxSeparation=3, verbose=true)

k = 10

println("\nOutbound expansion")
for (rank, id) in enumerate(fwdCountIDs[argmaxk(fwdCounts, k)])
    ttl = fwg.pm.id2title[id]
    println("\n> Top $(rank): $(ttl) <")
    reachability(fwg, id, bwg; maxSeparation=1, verbose=false)
end

println("\nInbound expansion")
for (rank, id) in enumerate(bwdCountIDs[argmaxk(bwdCounts, k)])
    ttl = bwg.pm.id2title[id]
    println("\n> Top $(rank): $(ttl) <")
    reachability(bwg, id, fwg; maxSeparation=1, verbose=false)
end

if ispath("output/fwdTop1000.txt")
    rm("output/fwdTop1000.txt")
end

open("output/fwdTop1000.txt", "a") do f
    for (rank, id) in enumerate(fwdCountIDs[argmaxk(fwdCounts, 1000)])
        write(f, "$(rank) $(fwg.pm.id2title[id])\n")
    end
end

if ispath("output/bwdTop1000.txt")
    rm("output/bwdTop1000.txt")
end

open("output/bwdTop1000.txt", "a") do f
    for (rank, id) in enumerate(bwdCountIDs[argmaxk(bwdCounts, 1000)])
        write(f, "$(rank) $(bwg.pm.id2title[id])\n")
    end
end
