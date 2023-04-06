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

function logHistogram(
        data, bins, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000, ysc="log"
    )
    hist(data, bins=bins)
    yscale(ysc)
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()
end

function logHistogramScaled(
        data, bins, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000, ysc="log",
        yl=1e+7, xl=3e+5
    )
    hist(data, bins=bins)
    yscale(ysc)
    ylim(0, yl)
    xlim(-2500, xl)
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()
end

function scat(
        outdegrees, indegrees, fname, ttl;
        xlab="Outdegree", ylab="Indegree", dpi=1000, sz=0.05, ysc="log", dims=(9, 12)
    )
    plt = scatter(outdegrees, indegrees, s=sz, marker=".")
    plt.set_sizes(dims, dpi=dpi)
    yscale(ysc)
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()
end

fwg = loadwgQuick("../graph/", "../data/enwiki-20230101-all-titles-in-ns0")
fwdCounts, fwdCountIDs = countlinks(fwg)
fwdNZCounts = [i for i in fwdCounts if i != 0]
logHistogram(fwdNZCounts, 1000, "output/outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")
logHistogramScaled(fwdNZCounts, 1000, "output/scaled_outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")

bwg = loadwgQuick("../backgraph/", "../data/enwiki-20230101-all-titles-in-ns0")
bwdCounts, bwdCountIDs = countlinks(bwg)
bwdNZCounts = [i for i in bwdCounts if i != 0]
logHistogram(bwdNZCounts, 1000, "output/indegree.png", "Distribution of Indegree over Pages with Indegree > 0")
logHistogramScaled(bwdNZCounts, 1000, "output/scaled_indegree.png", "Distribution of Indegree over Pages with Indegree > 0")

scat(fwdCounts, bwdCounts, "output/in-out.png", "Relationship between Indegree and Outdegree of Wikipedia Pages")

analyse(fwdCounts, "Outdegrees")
analyse(fwdNZCounts, "Non-Zero Outdegrees")
analyse(bwdCounts, "Indegrees")
analyse(bwdNZCounts, "Non-Zero Indegrees")

E = sum(fwdCounts)
V = length(fwdCounts)
density = sum(fwdCounts) / (V * (V - 1))
print("Density of Wikipedia links: $(density)")
