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


using Printf
using PyPlot
using CurveFit
using Pingouin
using Statistics
using ProgressBars
using Distributions
using DataStructures

include("../version.jl")
include("../wikigraph.jl")
include("exutils.jl")
include("indices.jl")

fwg = loadwgQuick("../graph/", "../data/enwiki-$(DATE)-all-titles-in-ns0")
fwdCounts, fwdCountIDs = countlinks(fwg)
fwdNZCounts = [i for i in fwdCounts if i != 0]

bwg = loadwgQuick("../backgraph/", "../data/enwiki-$(DATE)-all-titles-in-ns0")
bwdCounts, bwdCountIDs = countlinks(bwg)
bwdNZCounts = [i for i in bwdCounts if i != 0]


function runfunc(func, id)
    indeg = length(bwg.links[id])
    outdeg = length(fwg.links[id])
    return func(indeg, outdeg)
end
