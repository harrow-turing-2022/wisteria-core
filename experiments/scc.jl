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

        if lowLinks[u] == times[u]
            createScc(u)
        end

        if u == src
            return 0, false
        end
        
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

scc = tarjan(fwg)
