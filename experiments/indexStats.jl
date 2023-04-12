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


function graphfunc(
        func, bins, fname, ttl, xlab;
        ylab="Frequency density", dpi=1000, ysc="log", 
        color="orange", yfontsz=10, approx=false, dist=Normal
    )
    raw = [runfunc(func, i) for i in fwdCountIDs]
    data = [i for i in raw if !isnan(i) && i ∉ (Inf, -Inf)]

    n, b, _ = hist(data, bins=bins, color=color, density=approx)
    yscale(ysc)
    title(ttl)
    xlabel(xlab)
    ylabel(ylab, fontsize=yfontsz)

    if approx
        D = fit_mle(dist, data)
        x = LinRange(b[begin], b[end], 1000)
        y = [pdf(D, i) for i in x]
        plot(x, y, color="green")
    end

    savefig(fname, dpi=dpi)
    cla()
end


function statsfunc(func, name)
    raw = [runfunc(func, i) for i in fwdCountIDs]
    data = [i for i in raw if !isnan(i) && !(i in (Inf, -Inf))]
    analyse(data, "$(name) w/o {NaN, Inf, -Inf}")
    println("> $(name) with everything <")
    println("| Length:\t$(length(raw))")
    println("| NaN Count:\t$(length([i for i in raw if isnan(i)]))")
    println("| -Inf Count:\t$(length([i for i in raw if i == -Inf]))")
    println("| Inf Count:\t$(length([i for i in raw if i == Inf]))")

    return (raw, data)
end


function writeMaxK(func, k, fname)
    data = []
    ids = []

    for i in fwdCountIDs
        r = runfunc(func, i)
        if r ∉ (-Inf, Inf, NaN)
            push!(data, r)
            push!(ids, i)
        end
    end

    checkfile(fname)
    open(fname, "a") do f
        for (rank, i) in enumerate(argmaxk(data, k))
            id = ids[i]
            score = data[i]
            write(f, "$(rank) $(fwg.pm.id2title[id]) $(score)\n")
        end
    end
end


function writeMinK(func, k, fname)
    data = []
    ids = []

    for i in fwdCountIDs
        r = runfunc(func, i)
        if r ∉ (-Inf, Inf, NaN)
            push!(data, r)
            push!(ids, i)
        end
    end

    checkfile(fname)
    open(fname, "a") do f
        for (rank, i) in enumerate(argmink(data, k))
            id = ids[i]
            score = data[i]
            write(f, "$(rank) $(fwg.pm.id2title[id]) $(score)\n")
        end
    end
end


function writeSample(
        func, fname;
        samp = [
            "Philosophy", "Titanic", "Lionel_Messi", "The_Harrovian", 
            "United_States", "China", "Scientist", "British_Science_Association",
            "Ana_de_Armas", "Daniel_Craig", "Tom_Cruise", "Coldplay", "Albert_Einstein", "Alan_Turing",
            "Mathematics", "Number_theory", "Algebra", "Linear_algebra", "Rouché–Capelli_theorem",
            "Graph_theory", "Fermat's_Last_Theorem", "Fermat's_little_theorem", "Ulam_spiral",
            "Vector_space", "Matrix_(mathematics)", "Determinant", "Gaussian_elimination",
            "Row_echelon_form", "Vandermonde_matrix", "Zeckendorf's_theorem", "Stigler's_law_of_eponymy",
            "Leonhard_Euler"
        ]
    )
    data = [runfunc(func, fwg.pm.title2id[t]) for t in samp]

    checkfile(fname)
    open(fname, "a") do f
        for i in sortperm(data)
            ttl = samp[i]
            score = data[i]
            write(f, "$(ttl) $(score)\n")
        end
    end
end


funcs = [α, ϵ, λ, χ, κ, κ_prime]
names = ["alpha", "epsilon", "lambda", "chi", "kappa", "kappa_prime"]
symbols = ["α", "ϵ", "λ", "χ", "κ", "κ'"]

for (fn, nm, sy) in zip(funcs, names, symbols)
    graphfunc(fn, 500, "output/lin_$(nm).png", "Distribution of $(sy) scores", sy; ysc="linear", yfontsz=8)
    graphfunc(fn, 500, "output/log_$(nm).png", "Distribution of $(sy) scores", sy)
    writeMaxK(fn, 1000, "output/$(nm)_top1000.txt")
    writeMinK(fn, 1000, "output/$(nm)_bot1000.txt")
    writeSample(fn, "output/$(nm)_sample.txt")
    _, _ = statsfunc(fn, nm)
end


kappaRaw, kappaData = statsfunc(κ, "kappa")
kappa4000 = rand(1:length(kappaData), 4000)
normality(kappaData[kappa4000])
graphfunc(
    κ, 500, "output/lin_norm_kappa.png", "Normal Distribution Approximation of κ Scores", "κ";
    ysc="linear", yfontsz=8, approx=true, dist=Normal
)


kappaPRaw, kappaPData = statsfunc(κ_prime, "kappa prime")
kappaP4000 = rand(1:length(kappaPData), 4000)
normality(kappaPData[kappaP4000])
graphfunc(
    κ_prime, 500, "output/lin_norm_kappa_prime.png", "Normal Distribution Approximation of κ' Scores", "κ'";
    ysc="linear", yfontsz=8, approx=true, dist=Normal
)
