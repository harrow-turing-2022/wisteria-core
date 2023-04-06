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
include("exutils.jl")
include("../wikigraph.jl")
include("indices.jl")

fwg = loadwgquick("../graph/", "../data/enwiki-20230101-all-titles-in-ns0")
fwdCounts, fwdCountIDs = countlinks(fwg)
bwg = loadwgQuick("../backgraph/", "../data/enwiki-20230101-all-titles-in-ns0")
bwdCounts, bwdCountIDs = countlinks(bwg)


function runfunc(func, id)
    indeg = length(bwg.links[id])
    outdeg = length(fwg.links[id])
    return func(indeg, outdeg)
end


function testfunc(
        func; singlePages=25, doublePages=25,
        singleDemos=[
            "Philosophy", "Linear_algebra", "Titanic", "Lionel_Messi", 
            "Rouché–Capelli_theorem", "The_Harrovian"
        ]
    )

    absolute = []
    comparative = []

    println("WIKIPEDIA RELEVANCE INDEX")
    println("Please use the relevance scores of these following pages as a broad reference for your input:")

    for title in singleDemos
        id = fwg.pm.title2id[title]
        println("$(title) → $(runfunc(func, id))")
    end

    println("\nWe will show you 10 test pages; please input what you perceive their relevance to be:")

    for (e, _id) in enumerate(rand(1:fwg.pm.numpages, 10))
        id = fwdCountIDs[_id]
        title = fwg.pm.id2title[id]
        pred = runfunc(func, id)

        print("$(e): $(title) ")
        score = parse(Float64, readline())

        println("[$(pred)]")
    end

    println("\nWe will show you $(singlePages) pages; please input what you perceive their relevance to be:")

    for (e, _id) in enumerate(rand(1:fwg.pm.numpages, singlePages))
        id = fwdCountIDs[_id]
        title = fwg.pm.id2title[id]
        pred = runfunc(func, id)

        print("$(e): $(title) ")
        score = parse(Float64, readline())

        println("[$(pred)]")

        push!(absolute, (id, pred => score))
    end

    println("\nNow we will show you $(doublePages) pairs of pages, with their comparative relavance. Please state whether you think it is a fair characterisation.")
    for (e, (_id1, _id2)) in enumerate(zip(rand(1:fwg.pm.numpages, doublePages), rand(1:fwg.pm.numpages, doublePages)))
        id1 = fwdCountIDs[_id1]
        title1 = fwg.pm.id2title[id1]
        pred1 = runfunc(func, id1)

        id2 = fwdCountIDs[_id2]
        title2 = fwg.pm.id2title[id2]
        pred2 = runfunc(func, id2)

        if pred1 > pred2
            sto = 1
            print("$(e): $(title1) > $(title2)")
        elseif pred1 == pred2
            sto = 0
            print("$(e): $(title1) = $(title2)")
        else
            sto = -1
            print("$(e): $(title2) > $(title1)")
        end
        
        print("; Do you agree? [y/n/u] ")
        x = readline()
        ans = (x == "y" ? 1 : x == "u" ? 0 : -1)

        push!(comparative, (id1, id2, (pred1 - pred2) => ans))
    end

    return (absolute, comparative)
end


function analyseAbs(absData, funcname, fname; start=1, maxLen=Inf, dpi=1000)
    x, y = [], []
    for (id, (pred, score)) in absData[start:end]
        if isnan(pred) || pred in (-Inf, Inf)
            continue
        end
        push!(x, pred)
        push!(y, score)
        if length(x) == maxLen
            break
        end
    end

    println("$(funcname) Correlation: $(cor(x, y))")

    scatter(x, y)
    title("Alignment of $(funcname) with human perception of page relevance")
    xlabel("$(funcname) score")
    ylabel("Human perception")
    savefig(fname, dpi=dpi)
    cla()
end


function analyseCom(comData, funcname, fname; start=1, maxLen=Inf, dpi=1000)
    diff = []
    ans = []

    for (id1, id2, (_diff, _ans)) in comData
        if isnan(_diff) && _diff in (-Inf, Inf)
            continue
        end
        push!(diff, _diff)
        push!(ans, _ans)
        if length(x) == maxLen
            break
        end
    end

    labels = ["correct", "unsure", "wrong"]
    sizes = [count(i->(i==1), ans), count(i->(i==0), ans), count(i->(i==-1), ans)]
    colors = ["green", "grey", "red"]
    pie(sizes, labels=labels, autopct="%1.1f%%", colors=colors)
    title("Human evaluation of comparative page relevances")
    savefig(fname, dpi=dpi)
    cla()
end

κ_abs, κ_com = testfunc(κ)
analyseAbs(κ_abs, "κ", "output/kappa_correlation.png")
analyseCom(κ_com, "κ", "output/kappa_pie.png")

κp_abs, κp_com = testfunc(κ_prime)
analyseAbs(κp_abs, "κ'", "output/kappa_prime_correlation.png")
analyseCom(κp_com, "κ'", "output/kappa_prime_pie.png")
