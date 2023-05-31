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


include("version.jl")
include("wikigraph.jl")

println("Loading Wikigraph from checkpoint")
@time wg = loadwg("graph/", "data/enwiki-$(DATE)-all-titles-in-ns0")

println("Serialising for LGL (.NCOL)")
@time toNCOL("ser/graph.ncol", wg; uniformWeight=true)

println("Serialising for LGL (.LGL)")
@time toLGL("ser/graph.lgl", wg; uniformWeight=true)

println("Serialising for Cosmograph (.CSV)")
@time toCosmo("ser/graph.csv", wg; uniformWeight=true)
