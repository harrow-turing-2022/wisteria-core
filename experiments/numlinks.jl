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

function loglogHistogram(
        data, bins, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000
    )
    hist(data, bins=bins)
    yscale("log")
    xscale("log")
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

function loglogHistogramScaled(
        data, bins, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000,
        yl=1e+7, xl=3e+5
    )
    hist(data, bins=bins)
    yscale("log")
    xscale("log")
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
        xlab="Outdegree", ylab="Indegree", dpi=1000, sz=1
    )
    scatter(outdegrees, indegrees, s=sz, marker=".")
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()
end

function loglogscat(
        outdegrees, indegrees, fname, ttl;
        xlab="Outdegree", ylab="Indegree", dpi=1000, sz=1
    )
    scatter(outdegrees, indegrees, s=sz, marker=".")
    yscale("log")
    xscale("log")
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()
end

logHistogram(fwdCounts, 1000, "output/outdegree.png", "Distribution of Outdegree")
logHistogramScaled(fwdCounts, 1000, "output/scaled_outdegree.png", "Distribution of Outdegree")
loglogHistogram(fwdCounts, 1000, "output/loglog_outdegree.png", "Distribution of Outdegree")
loglogHistogramScaled(fwdCounts, 1000, "output/scaled_loglog_outdegree.png", "Distribution of Outdegree")

logHistogram(fwdNZCounts, 1000, "output/nz_outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")
logHistogramScaled(fwdNZCounts, 1000, "output/nz_scaled_outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")
loglogHistogram(fwdNZCounts, 1000, "output/nz_loglog_outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")
loglogHistogramScaled(fwdNZCounts, 1000, "output/nz_scaled_loglog_outdegree.png", "Distribution of Outdegree over Pages with Outdegree > 0")

logHistogram(bwdCounts, 1000, "output/indegree.png", "Distribution of Indegree")
logHistogramScaled(bwdCounts, 1000, "output/scaled_indegree.png", "Distribution of Indegree")
loglogHistogram(bwdCounts, 1000, "output/loglog_indegree.png", "Distribution of Indegree")
loglogHistogramScaled(bwdCounts, 1000, "output/scaled_loglog_indegree.png", "Distribution of Indegree")

logHistogram(bwdNZCounts, 1000, "output/nz_indegree.png", "Distribution of Indegree over pages with Indegree > 0")
logHistogramScaled(bwdNZCounts, 1000, "output/nz_scaled_indegree.png", "Distribution of Indegree over pages with Indegree > 0")
loglogHistogram(bwdNZCounts, 1000, "output/nz_loglog_indegree.png", "Distribution of Indegree over pages with Indegree > 0")
loglogHistogramScaled(bwdNZCounts, 1000, "output/nz_scaled_loglog_indegree.png", "Distribution of Indegree over pages with Indegree > 0")

scat(fwdCounts, bwdCounts, "output/in-out.png", "Relationship between Indegree and Outdegree of Wikipedia Pages")
loglogscat(fwdCounts, bwdCounts, "output/loglog_in-out.png", "Relationship between Indegree and Outdegree of Wikipedia Pages")

analyse(fwdCounts, "Outdegrees")
analyse(fwdNZCounts, "Non-Zero Outdegrees")
analyse(bwdCounts, "Indegrees")
analyse(bwdNZCounts, "Non-Zero Indegrees")

fwdE = sum(fwdCounts)
fwdV = length(fwdCounts)
fwdDensity = fwdE / (fwdV * (fwdV - 1))
print("Outbound Graph: E = $(fwdE) | V = $(fwdV)")
print("Density of outbound links: $(fwdDensity)")

bwdE = sum(bwdCounts)
bwdV = length(bwdCounts)
bwdDensity = bwdE / (bwdV * (bwdV - 1))
print("Inbound Graph: E = $(bwdE) | V = $(bwdV)")
print("Density of inbound links: $(bwdDensity)")
