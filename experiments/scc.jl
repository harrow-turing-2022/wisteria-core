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


include("common.jl")


function tarjan(wg::WikigraphUnweighed)
    t = 0
    stack = Stack{Int32}()

    times = Int32[0 for _ = 1:wg.pm.totalpages]
    lowLinks = Int32[0 for _ = 1:wg.pm.totalpages]
    parents = Int32[0 for _ = 1:wg.pm.totalpages]
    positions = Int32[0 for _ = 1:wg.pm.totalpages]
    lens = [length(i) for i in wg.links]

    onStack = Set{Int32}()
    scc = Set{Int32}[]

    function init(u)
        t += 1
        times[u] = t
        lowLinks[u] = t
        push!(stack, u)
        push!(onStack, u)
    end

    function createScc(u)
        component = Set{Int32}()
        while (v = pop!(stack)) != u
            pop!(onStack, v)
            push!(component, v)
        end
        pop!(onStack, u)
        push!(component, u)
        push!(scc, component)
    end

    function next(u, src)
        pos = positions[u] + 1
        
        for i = pos:lens[u]
            v = wg.links[u][i]

            if times[v] == 0
                positions[u] = i
                parents[v] = u
                return v, true
            end

            (v in onStack) && (lowLinks[u] = min(lowLinks[u], times[v]))
        end

        (lowLinks[u] == times[u]) && createScc(u)

        (u == src) && (return 0, false)
        
        return parents[u], false
    end

    function strongConnect(src)
        init(src)
        u = src

        while ((v, new) = next(u, src)) != (0, false)
            if new
                init(v)
            else
                lowLinks[v] = min(lowLinks[v], lowLinks[u])
            end
            u = v
        end
    end

    trueIDs = [i for i = 1:wg.pm.totalpages if notRedir(wg.pm, i)]

    for u in ProgressBar(trueIDs)
        (times[u] == 0) && strongConnect(u)
    end

    return scc
end


function initFrontier!(frontier::Set{Int32}, explored::Set{Int32}, 
    cache::Dict{Int32, Set{Int32}}, cached::Set{Int32})
    setdiff!(frontier, explored)
    overlap = intersect(frontier, cached)
    for i in overlap
        union!(explored, cache[i])
    end
    setdiff!(frontier, overlap)
end

function bfs!(wg::WikigraphUnweighed, source::Integer, cache::Dict{Int32, Set{Int32}})
    cached = Set(keys(cache))
    explored = Set{Int32}([source])
    frontier = Set(wg.links[source])
    initFrontier!(frontier, explored, cache, cached)

    while length(frontier) > 0
        newFrontier = Int32[]

        for id in frontier
            append!(newFrontier, wg.links[id])
        end
        union!(explored, frontier)

        frontier = Set(newFrontier)
        initFrontier!(frontier, explored, cache, cached)
    end

    union!(explored, frontier)
    cache[source] = explored
    return explored
end


scc = tarjan(fwg)
sizes = [length(i) for i in scc]
maxSz = maximum(sizes)
maxIdx = argmax(sizes)
println("Biggest SCC is codenamed the *$(fwg.pm.id2title[collect(scc[maxIdx])[1]]) cluster*")


checkfile("output/scc$(maxIdx)_$(maxSz).txt")
open("output/scc$(maxIdx)_$(maxSz).txt", "a") do f
    for id in scc[maxIdx]
        write(f, fwg.pm.id2title[id], "\n")
    end
end


isolated = Set{Int32}([i for i = 1:fwg.pm.totalpages if notRedir(fwg.pm, i) && length(fwg.links[i]) == 0])
initialComps = Set{Int32}()
for i in scc
    if length(i) == 1
        union!(initialComps, i)
    else
        break
    end
end
println("Length of initial chunk of length-1 SCCs: $(length(initialComps))")
println("Length of isolated pages in forward Wikigraph: $(length(isolated))")


x = sort(collect(Set(sizes)))
y = [count(i->i==sz, sizes) for sz in x]

println("SCC size\tCount\t% Wikipedia covered in (each) SCC")
for (sz, cnt) in zip(x, y)
    println("$(sz)\t$(cnt)\t$(sz * 100 / fwg.pm.numpages)")
end

scatter(x, y, s=2, marker=".")
yscale("log")
xscale("log")
title("Number of Wikipedia SCC across different sizes")
xlabel("Size of strongly-connected component")
ylabel("Count")
savefig("output/scc_count_dots.png", dpi=1000)
cla()

plot(x, y)
yscale("log")
xscale("log")
title("Number of Wikipedia SCC across different sizes")
xlabel("Size of strongly-connected component")
ylabel("Count")
savefig("output/scc_count_line.png", dpi=1000)
cla()


#=
selects = [collect(i)[begin] for i in scc]

fwdCache = Dict{Int32, Set{Int32}}()
fwdReachables = [length(bfs!(fwg, i, fwdCache)) for i in ProgressBar(selects)]

bwdCache = Dict{Int32, Set{Int32}}()
bwdReachables = [length(bfs!(bwg, i, bwdCache)) for i in ProgressBar(reverse(selects))]
#=
