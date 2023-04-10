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


function expandBFS(wg::WikigraphUnweighed, source::Integer; 
    maxSeparation=Inf, verbose=false, printEach=false, nzCount=0)

    s = 1
    r = 0
    explored = Set{Int32}([source])
    separations = Int32[]
    frontier = Set(wg.links[source])
    push!(separations, length(frontier))
    
    if printEach
        ttl = wg.pm.id2title[source]
        numReached = length(frontier)
        println("At $(s) degrees of separation $(ttl) reaches:")
        println("| $(numReached) articles")
        println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia pages")
        println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia pages")
    end

    while length(frontier) > 0 && s < maxSeparation
        newFrontier = Int32[]

        if verbose
            println("Expanding nodes of separation $(s+1)")
            iter = ProgressBar(frontier)
        else
            iter = frontier
        end

        for id in iter
            append!(newFrontier, wg.links[id])
        end
        union!(explored, frontier)

        frontier = Set(newFrontier)
        setdiff!(frontier, explored)
        r = length(frontier)
        
        if r == 0
            break
        end

        s += 1
        push!(separations, r)

        if printEach
            numReached = length(explored) + r
            println("At $(s) degrees of separation $(ttl) reaches:")
            println("| $(numReached) articles")
            println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia pages")
            println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia pages")
        end
    end

    union!(explored, frontier)
    return (explored, separations, s, r)
end


function writeSCC(idx, sz)
    checkfile("output/scc$(idx)_$(sz).txt")
    open("output/scc$(idx)_$(sz).txt", "a") do f
        for id in scc[idx]
            write(f, fwg.pm.id2title[id], "\n")
        end
    end
end


scc = tarjan(fwg)
sizes = [length(i) for i in scc]
maxSz = maximum(sizes)
maxIdx = argmax(sizes)
println("Biggest SCC is codenamed the *$(fwg.pm.id2title[collect(scc[maxIdx])[begin]]) cluster*")

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

println("SCC size\tCount\t% Wikipedia covered in (each) SCC\t[codename]")
for (sz, cnt) in zip(x, y)
    if cnt == 1
        idx = findfirst(==(sz), sizes)
        print("$(sz)\t$(cnt)\t$(sz * 100 / fwg.pm.numpages)\t")
        println(fwg.pm.id2title[collect(scc[idx])[begin]])
        writeSCC(idx, sz)
    else
        println("$(sz)\t$(cnt)\t$(sz * 100 / fwg.pm.numpages)")
    end
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


selects = [collect(i)[begin] for i in scc]

fwdSrc = 0
for i in reverse(selects)
    if length(fwg.links[i]) > 0
        fwdSrc = i
        break
    end
end
expandBFS(fwg, fwdSrc; printEach=true, nzCount=length(bwdNZCounts))

bwdSrc = 0
for i in selects
    if length(bwg.links[i]) > 0
        bwdSrc = i
        break
    end
end
expandBFS(bwg, bwdSrc; printEach=true, nzCount=length(fwdNZCounts))
