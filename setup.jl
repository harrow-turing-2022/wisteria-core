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

import Pkg
include("version.jl")


Pkg.add(["EzXML", "FileIO", "JLD2", "JSON", "ProgressBars", "PyPlot", "CurveFit",
         "Pingouin", "Distributions", "DataStructures", "Genie"])
println("✅ All Julia packages installed")

safemake(dir) = !ispath(dir) && mkdir(dir)
safemake("data")
safemake("logs")
safemake("ser")
println("✅ All directories created")

if Sys.islinux()
    run(`sudo apt-get update`)
    run(`sudo apt-get install curl p7zip-full`)
end

function checkInstall!(list::Vector{String}, pkg::String, test::Cmd)
    try
        run(test)
    catch err
        push!(list, pkg)
    end
end

uninstalled = String[]
checkInstall!(uninstalled, "curl", `curl -V`)
checkInstall!(uninstalled, "curl", `7z`)
checkInstall!(uninstalled, "Python (for PyPlot)", `python --version`)

if "Python (for PyPlot)" ∉ uninstalled
    run(`pip install matplotlib`)
end

if length(uninstalled) > 0
    error("❌ The following commands are not available: $(uninstalled)\n")
else
    println("✅ All required commands available")
end


if !ispath("data/enwiki-$(DATE)-all-titles-in-ns0")
    run(`curl https://dumps.wikimedia.org/enwiki/$(DATE)/enwiki-$(DATE)-all-titles-in-ns0.gz --output enwiki-$(DATE)-all-titles-in-ns0.gz`)
    run(`7z x enwiki-$(DATE)-all-titles-in-ns0.gz -odata`)
    rm("enwiki-$(DATE)-all-titles-in-ns0.gz")
end
if !ispath("data/dumpstatus.json")
    run(`curl https://dumps.wikimedia.org/enwiki/$(DATE)/dumpstatus.json --output data/dumpstatus.json`)
end
println("✅ All prerequisite files downloaded")

import JSON
status = JSON.parsefile("data/dumpstatus.json")
multistreams = collect(keys(status["jobs"]["articlesmultistreamdump"]["files"]))
filter!(x -> x[43:48] != "-index", multistreams)
multistreams = sort( multistreams; by = x -> parse(Int64, split(split(x, ".xml-p")[2], "p")[1]) )
write("data/multistream-urls.txt", join(multistreams, "\n"))
println("✅ Multistream URLs generated")

println("✅ Setup complete")
