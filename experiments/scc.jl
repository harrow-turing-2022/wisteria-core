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


function tarjan(wg::WikigraphUnweighed, rwg::WikigraphUnweighed)
    t = 0
    id = 0
    stack = Stack{Int32}()

    times = Int32[0 for _ = 1:wg.pm.totalpages]
    lowLinks = Int32[0 for _ = 1:wg.pm.totalpages]
    parents = Int32[0 for _ = 1:wg.pm.totalpages]
    positions = Int32[0 for _ = 1:wg.pm.totalpages]
    lens = [length(i) for i in wg.links]

    onStack = Set{Int32}()
    scc = Set{Int32}[]
    gscc = Set{Int32}[]
    gscclinks = Set{Int32}[Set() for _ = 1:wg.pm.totalpages]

    function init(u)
        t += 1
        times[u] = t
        lowLinks[u] = t
        push!(stack, u)
        push!(onStack, u)
    end

    function addToComponent(component, v)
        pop!(onStack, v)
        push!(component, v)
        for x in rwg.links[v]
            push!(gscclinks[x], id)
        end
    end

    function createScc(u)
        id += 1
        component = Set{Int32}()
        while (v = pop!(stack)) != u
            addToComponent(component, v)
        end
        addToComponent(component, u)
        push!(scc, component)

        lk = Set{Int32}()
        for i in component
            union!(lk, gscclinks[i])
        end
        setdiff!(lk, Set{Int32}(id))
        push!(gscc, lk)
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

    return scc, gscc
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


function gsccBFS(scc::Vector{Set{Int32}}, gscc::Vector{Set{Int32}}, source::Integer)
    explored = Set{Int32}(source)
    frontier = gscc[source]
    numReached = length(scc[source])

    while length(frontier) > 0
        newFrontier = Set{Int32}()

        for id in frontier
            numReached += length(scc[id])
            union!(newFrontier, gscc[id])
        end
        union!(explored, frontier)

        frontier = setdiff(newFrontier, explored)
    end

    return numReached
end


function writeSCC(idx, sz)
    checkfile("output/scc$(idx)_$(sz).txt")
    open("output/scc$(idx)_$(sz).txt", "a") do f
        for id in scc[idx]
            write(f, fwg.pm.id2title[id], "\n")
        end
    end
end


scc, gscc = tarjan(fwg, bwg)

numSCC = length(scc)
sizes = [length(i) for i in scc]
maxSz = maximum(sizes)
maxIdx = argmax(sizes)
println("Wikipedia has $(numSCC) SCCs")
println("Biggest SCC is codenamed the *$(fwg.pm.id2title[collect(scc[maxIdx])[begin]]) cluster*")

sinks = Set{Int32}([i for i = 1:fwg.pm.totalpages if notRedir(fwg.pm, i) && length(fwg.links[i]) == 0])
initialComps = Set{Int32}()
for i in scc
    if length(i) == 1
        union!(initialComps, i)
    else
        break
    end
end
println("Length of initial chunk of length-1 SCCs: $(length(initialComps))")
println("Length of sink pages in forward Wikigraph: $(length(sinks))")


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


scatter(x, y, s=4, marker=".", color="mediumpurple")
yscale("log")
xscale("log")
# title("Number of Wikipedia SCC of different sizes")
xlabel("Size of SCC")
ylabel("Count")
savefig("output/scc_count_dots.png", dpi=1000)
cla()

scatter(x, y, s=15, marker="x", color="mediumpurple")
yscale("log")
xscale("log")
# title("Number of Wikipedia SCC of different sizes")
xlabel("Size of SCC")
ylabel("Count")
savefig("output/scc_count_crosses.png", dpi=1000)
cla()

scatter(x, y, s=15, marker="1", color="mediumpurple")
yscale("log")
xscale("log")
# title("Number of Wikipedia SCC of different sizes")
xlabel("Size of SCC")
ylabel("Count")
savefig("output/scc_count_tri.png", dpi=1000)
cla()

plot(x, y, color="mediumpurple")
yscale("log")
xscale("log")
# title("Number of Wikipedia SCC of different sizes")
xlabel("Size of SCC")
ylabel("Count")
savefig("output/scc_count_line.png", dpi=1000)
cla()

bar(x, y, color="mediumpurple")
yscale("log")
xscale("log")
# title("Number of Wikipedia SCC of different sizes")
xlabel("Size of SCC")
ylabel("Count")
savefig("output/scc_count_bar.png", dpi=1000)
cla()


selects = [collect(i)[begin] for i in scc]
maxSCC = scc[maxIdx]

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


fwdReaches = [gsccBFS(scc, gscc, i) for i in ProgressBar(numSCC:-1:maxIdx+1)]
fwdMaxReach = maximum(fwdReaches)
for (scc_i, reach) in enumerate(fwdReaches)
    if reach == fwdMaxReach
        correct_scc_i = numSCC + 1 - scc_i
        println("Most reachy fwd SCC is #$(correct_scc_i) at $(fwdMaxReach) articles")
        println("It contains: $([fwg.pm.id2title[id] for id in scc[correct_scc_i]])")
    end
end


gscc_T = Set{Int32}[Set() for _ = 1:numSCC]
for (u, lk) in enumerate(gscc)
    for v in lk
        push!(gscc_T[v], u)
    end
end
bwdReaches = [gsccBFS(scc, gscc_T, i) for i in ProgressBar(1:maxIdx-1)]
bwdMaxReach = maximum(bwdReaches)
for (scc_i, reach) in enumerate(bwdReaches)
    if reach == bwdMaxReach
        println("Most reachy fwd SCC is #$(scc_i) at $(bwdMaxReach) articles")
        println("It contains: $([bwg.pm.id2title[id] for id in scc[scc_i]])")
    end
end


gsccOutdegs = [length(gscc[i]) for i = 1:numSCC]
for (rank, scc_i) in enumerate(argmaxk(gsccOutdegs, 10))
    outdeg = gsccOutdegs[scc_i]
    println("Top $(rank) SCC #$(scc_i) : deg+ = $(outdeg)")
end

gsccIndegs = [length(gscc_T[i]) for i = 1:numSCC]
for (rank, scc_i) in enumerate(argmaxk(gsccIndegs, 10))
    indeg = gsccIndegs[scc_i]
    println("Top $(rank) SCC #$(scc_i) : deg- = $(indeg)")
end
