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


using Statistics
include("../wikigraph.jl")


function countlinks(wg::Union{Wikigraph, WikigraphUnweighed})
    counts = Int32[]
    countIDs = Int32[]

    for srcID in ProgressBar(1:wg.pm.totalpages)
        if notRedir(wg.pm, srcID)
            push!(countIDs, srcID)
            push!(counts, length(wg.links[srcID]))
        end
    end

    return counts, countIDs
end

function countIsolated(wg::Union{Wikigraph, WikigraphUnweighed})
    isolated = Int32[]

    for srcID in ProgressBar(1:wg.pm.totalpages)
        if notRedir(wg.pm, srcID) && length(wg.links[srcID] == 0)
            push!(isolated, srcID)
        end
    end

    return isolated
end

function analyse(arr, name)
    println("> $(name) <")
    println("| Length:\t$(length(arr))")
    println("| Sum:\t\t$(sum(arr))")
    println("| Mean:\t\t$(mean(arr))")
    println("| Median:\t$(median(arr))")
    println("| Stddv:\t$(std(arr))")
    println("| Variance:\t$(var(arr))")
    println("| 0 Count:\t$(count(i->(i==0), arr))")
end

function argmaxk(arr, k)
    return partialsortperm(arr, 1:k, rev=true)
end

function argmink(arr, k)
    return partialsortperm(arr, 1:k, rev=false)
end
