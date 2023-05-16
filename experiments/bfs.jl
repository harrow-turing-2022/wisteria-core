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
        println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia articles")
        println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia articles")
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
            println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia articles")
            println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia articles")
        end
    end

    union!(explored, frontier)
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


function connectBFS(wg::WikigraphUnweighed, source::Integer, target::Integer; verbose=false)
    s = 1
    explored = Int32[source]
    frontier = Set(wg.links[source])
    parents = Dict{Int32, Int32}(t => source for t in wg.links[source])

    if length(frontier) == 0
        return (Inf, [])
    elseif source == target
        return (0, [])
    end

    while length(frontier) > 0
        if target in frontier
            return (s, retrace(source, target, parents))
        end

        newFrontier = Int32[]

        if verbose
            println("Expanding nodes of separation $(s+1)")
            iter = ProgressBar(frontier)
        else
            iter = frontier
        end

        for id in iter
            append!(newFrontier, wg.links[id])
            for t in wg.links[id]
                (haskey(parents, t)) || (parents[t] = id)
            end
        end
        union!(explored, frontier)

        s += 1
        frontier = Set(newFrontier)
        setdiff!(frontier, explored)
    end

    return (Inf, [])
end


function race(wg::WikigraphUnweighed, startTitle::AbstractString, endTitle::AbstractString; verbose=false)
    @assert haskey(wg.pm.title2id, startTitle) "Start title $(startTitle) does not exist"
    @assert haskey(wg.pm.title2id, endTitle) "End title $(endTitle) does not exist"

    startID = wg.pm.title2id[startTitle]
    endID = wg.pm.title2id[endTitle]

    @assert notRedir(wg.pm, startID) "Start title $(startTitle) is a redirected article"
    @assert notRedir(wg.pm, endID) "End title $(endTitle) is a redirected article"

    deg, path = connectBFS(wg, startID, endID, verbose=verbose)

    println("Degree $(deg) separation:")
    for id in path
        println(wg.pm.id2title[id])
    end
end


norm(x) = join([isletter(x[i]) ? x[i] : '_' for i in eachindex(x)])


function reachability(
        wg::WikigraphUnweighed, source::Integer, nzCount; maxSeparation=Inf, verbose=false, printEach=false,
        graph=false, type="", yfontsz=10, dpi=1000, color="forestgreen"
    )

    (type == "") || (type = type * " ")
    ttl = wg.pm.id2title[source]

    explored, separations, s, _ = expandBFS(wg, source;
        maxSeparation=maxSeparation, verbose=verbose, printEach=printEach, nzCount=nzCount)
    
    if !printEach
        numReached = length(explored)
        println("At $(s) degrees of separation $(ttl) reaches:")
        println("| $(numReached) articles")
        println("| $(numReached * 100 / wg.pm.numpages)% of all Wikipedia articles")
        println("| $(numReached * 100 / nzCount)% of all reachable Wikipedia articles")
    end
    
    if graph
        bar([i for i = 1:s], separations, color=color)
        yscale("log")
        title("$(type)BFS expansion of $(ttl)")
        xlabel("Degree of separation")
        ylabel("Number of new articles reached", fontsize=yfontsz)
        savefig("output/bfsDif_$(norm(ttl))_deg$(s).pdf", bbox_inches="tight")
        cla()
        
        cumseps = cumsum(separations)
        plot([i for i = 1:s], cumseps, color=color)
        title("$(type)BFS expansion of $(ttl)")
        xlabel("Degree of separation")
        ylabel("Number of articles reached", fontsize=yfontsz)
        savefig("output/bfsCum_$(norm(ttl))_deg$(s).pdf", bbox_inches="tight")
        cla()

        plot([i for i = 1:s], cumseps / nzCount, color=color)
        title("$(type)BFS expansion of $(ttl)")
        xlabel("Degree of separation")
        ylabel("Number of articles reached (fraction of reachable)", fontsize=yfontsz)
        savefig("output/bfsCumScaled_$(norm(ttl))_deg$(s).pdf", bbox_inches="tight")
        cla()
    end
end


function bidirectionalBFS(fwg::WikigraphUnweighed, bwg::WikigraphUnweighed, source::Integer)
    explored = Set{Int32}([source])
    frontier = Set(fwg.links[source]) ∪ Set(bwg.links[source])

    while length(frontier) > 0
        newFrontier = Int32[]

        for id in frontier
            append!(newFrontier, fwg.links[id])
            append!(newFrontier, bwg.links[id])
        end
        union!(explored, frontier)

        frontier = Set(newFrontier)
        setdiff!(frontier, explored)
    end

    union!(explored, frontier)
    return explored
end


function findIslands()
    islands = Dict{String, Set{Int32}}()
    allExplored = Set{Int32}()
    iter = ProgressBar(sortperm(bwdCounts; rev=true))

    for idx in iter
        srcID = bwdCountIDs[idx]
        (srcID in allExplored || isRedir(fwg.pm, srcID)) && (continue)
        
        explored = bidirectionalBFS(fwg, bwg, srcID)
        union!(allExplored, explored)

        islands[fwg.pm.id2title[srcID]] = explored

        progress = length(allExplored) * 100 / fwg.pm.numpages
        set_postfix(iter, progress="$(round(progress; digits=2))  %Wikipedia")
    end

    return islands
end

race(fwg, "Julia_(programming_language)", "Goychay_District")
race(bwg, "Aeneid", "Tardigrade")

philID = fwg.pm.title2id["Philosophy"]
reachability(fwg, philID, length(bwdNZCounts); printEach=true, graph=true, type="Outbound")
reachability(bwg, philID, length(fwdNZCounts); printEach=true, graph=true, type="Inbound")

k = 10

println("\nOutbound expansion")
for (rank, id) in enumerate(fwdCountIDs[argmaxk(fwdCounts, k)])
    ttl = fwg.pm.id2title[id]
    println("\n> Top $(rank): $(ttl) <")
    reachability(fwg, id, length(bwdNZCounts); maxSeparation=1, verbose=false)
end

println("\nInbound expansion")
for (rank, id) in enumerate(bwdCountIDs[argmaxk(bwdCounts, k)])
    ttl = bwg.pm.id2title[id]
    println("\n> Top $(rank): $(ttl) <")
    reachability(bwg, id, length(fwdNZCounts); maxSeparation=1, verbose=false)
end


islands = findIslands()

checkfile("output/islands.txt")
cnt = 0

open("output/islands.txt", "a") do f
    for (k, s) in islands
        sz = length(s)
        if sz > 1
            cnt += 1
            println("$(k) : $(sz)")

            if sz < 10
                for ttl in fwg.pm.id2title[collect(islands[k])]
                    println("| $(ttl)")
                end
            end

        end
        write(f, fwg.pm.id2title[collect(islands[begin])], " : $(sz)\n")
    end
end

println("> $(length(islands)) islands in total")
println("> $(cnt) islands greater than 1 in total")
