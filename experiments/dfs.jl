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


function dfs(wg::WikigraphUnweighed, ids::Vector{Int32})
    lens = [length(i) for i in wg.links]
    
    status = Int32[0 for _ = 1:wg.pm.totalpages]
    parents = Int32[0 for _ = 1:wg.pm.totalpages]
    positions = Int32[0 for _ = 1:wg.pm.totalpages]
    populate = Dict{Int32, Set{Int32}}()
    reachables = Set{Int32}[Set{Int32}([i]) for i = ProgressBar(1:wg.pm.totalpages)]

    function next(u, src)
        pos = positions[u] + 1
        
        for i = pos:lens[u]
            v = wg.links[u][i]

            if status[v] == 0
                positions[u] = i
                parents[v] = u
                status[v] = 1
                return v
            elseif status[v] == 1
                push!(populate[v], u)
            elseif status[v] == 2
                union!(reachables[u], reachables[v])
            end
        end

        status[u] = 2

        for v in populate[u]
            union!(reachables[v], reachables[u])
        end
        populate[u] = Set{Int32}([])

        (u == src) && (return 0)
        
        parent = parents[u]
        union!(reachables[parent], reachables[u])
        return parent
    end

    for src in ProgressBar(ids)
        status[src] = 1
        u = src

        while (v = next(u, src)) != 0
            u = v
        end
    end

    return reachables[ids]
end
