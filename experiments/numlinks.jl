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
        data, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000, ysc="log", fit=false, bins=1000
    )

    (bins == 0) && (bins=maximum(data)-minimum(data)+1)
    hist(data, bins=bins)

    if fit
        x = []
        y = []
        for (i, c) in counter(data)
            if i > 0
                push!(x, i)
                push!(y, c)
            end
        end
        a, b = power_fit(x, y)

        fitX = [i for i in LinRange(minimum(data), maximum(data), bins * 2)]
        fitY = [a*(i^b) for i in fitX]
        line = plot(fitX, fitY, color="red", label=@sprintf("y = %.3e x^%.3f", a, b))[1]

        legend(handles=[line])
    end

    yscale(ysc)
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()

    if fit
        return a, b
    end
end

function loglogHistogram(
        data, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000, fit=false, bins=1000
    )

    (bins == 0) && (bins=maximum(data)-minimum(data)+1)
    hist(data, bins=bins)

    if fit
        x = []
        y = []
        for (i, c) in counter(data)
            if i > 0
                push!(x, i)
                push!(y, c)
            end
        end
        a, b = power_fit(x, y)

        fitX = [i for i in LinRange(minimum(data), maximum(data), bins * 2)]
        fitY = [a*(i^b) for i in fitX]
        line = plot(fitX, fitY, color="red", label=@sprintf("y = %.3e x^%.3f", a, b))[1]

        legend(handles=[line])
    end

    xscale("log")
    yscale("log")
    title(ttl)
    xlabel(xlab)
    ylabel(ylab)
    savefig(fname, dpi=dpi)
    cla()

    if fit
        return a, b
    end
end

function logHistogramScaled(
        data, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000,
        ysc="log", bins=1000, yl=1e+7, xl=3e+5
    )
    (bins == 0) && (bins=maximum(data)-minimum(data)+1)
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
        data, fname, ttl; 
        xlab="Number of links", ylab="Frequency density", dpi=1000,
        yl=1e+7, xl=3e+5, bins=1000
    )
    (bins == 0) && (bins=maximum(data)-minimum(data)+1)
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


arrs = [fwdCounts, fwdNZCounts, bwdCounts, bwdNZCounts]
names = ["outdegree", "outdegree", "indegree", "indegree"]
prefix = ["", "nz_", "", "nz_"]

for (a, n, p) in ProgressBar(zip(arrs, names, prefix))
    un = uppercasefirst(n)
    logHistogram(a, "output/$(p)$(n).png", "Distribution of $(un)")
    logHistogram(a, "output/fit_$(p)$(n).png", "Distribution of $(un)"; fit=true, bins=0)
    loglogHistogram(a, "output/$(p)loglog_$(n).png", "Distribution of $(un)")
    logHistogramScaled(a, "output/$(p)scaled_$(n).png", "Distribution of $(un)")
    loglogHistogramScaled(a, "output/$(p)scaled_loglog_$(n).png", "Distribution of $(un)")
end

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
