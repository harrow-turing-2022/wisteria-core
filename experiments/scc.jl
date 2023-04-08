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
    trueIDs = [i for i = 1:wg.pm.totalpages if notRedir(wg.pm, i)]

    stack = Stack{Int32}()
    t = 0

    times = Dict{Int32, Int32}()
    onStack = Set{Int32}()
    searched = Set{Int32}()
    scc = Set{Int32}[]

    function strongConnect(u)
        t += 1
        times[u] = t
        lowlink = t
        push!(stack, u)
        push!(onStack, u)
        push!(searched, u)

        for v in wg.links[u]
            if v ∉ searched
                vlow = strongConnect(v)
                lowlink = min(lowlink, vlow)
            elseif v in onStack
                lowlink = min(lowlink, times[v])
            end
        end

        if lowlink == times[u]
            component = Set{Int32}()
            while (v = pop!(stack)) != u
                pop!(onStack, v)
                push!(component, v)
            end
            pop!(onStack, u)
            push!(component, u)
            push!(scc, component)
        end

        return lowlink
    end

    for u in ProgressBar(trueIDs)
        (u in searched) || strongConnect(u)
    end

    return scc
end


scc = tarjan(fwg)
