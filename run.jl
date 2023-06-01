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


using Downloads
include("version.jl")
include("parser.jl")
include("wikigraph.jl")

function dunzip(fname)
    run(`curl https://dumps.wikimedia.org/enwiki/$DATE/$fname --output $fname`)
    run(`7z x $fname -odata`)
    rm(fname)
end

function main(wg, start, files)
    for i = start:length(files)
        if !ispath("logs/$(i)")
            mkdir("logs/$(i)")
        elseif ispath("logs/$(i)/title_errors.txt")
            rm("logs/$(i)/title_errors.txt")
        end
    
        zipname = files[i]
        xmlname = String(split(zipname, ".bz2")[1])
        numpages = parse(Int64, split(xmlname, "p")[end]) - parse(Int64, split(xmlname, "p")[end-1]) + 1
    
        println("\n[$(i)/$(length(files))] Starting on $(numpages) pages from $(zipname)")
    
        if !ispath("data/$(xmlname)")
            dunzip(zipname)
        end
        
        # Mines XML to update wg, and saves it back into `graph`    
        wg = mineXML(
            "data/$(xmlname)",
            wg,
            "graph/",
            "logs/$(i)/title_errors.txt",
            numpages
        )
    
        rm("data/$(xmlname)")
    end

    return wg
end


start = length(ARGS) == 0 ? 1 : parse(Int64, ARGS[1])
files = [String(strip(i)) for i in split(strip(read("data/multistream-urls.txt", String)), "\n")]

# Load wg from `graph/` if checkpointed, else initialise empty wg
if wgIntegrity("graph/")
    println("Loading Wikigraph from last checkpoint")
    @time wgraph = loadwg("graph/", "data/enwiki-$(DATE)-all-titles-in-ns0")
else
    println("Initialising empty Wikigraph from titles")
    @time wgraph = Wikigraph("data/enwiki-$(DATE)-all-titles-in-ns0")
end


# Run main parsing logic
main(wgraph, start, files)


# Clear memory
wgraph = 0
GC.gc()


# Serialise graphs

fwg = loadwg("graph/", "data/enwiki-$(DATE)-all-titles-in-ns0")
savewgQuick("graph/", fwg)
println("✅ Forward graph serialisation complete [$(fwg.pm.numpages) articles]")

bwg = loadwg("graph/", "data/enwiki-$(DATE)-all-titles-in-ns0"; backwards=true)
savewg("backgraph/", bwg)
savewgQuick("backgraph/", bwg)
println("✅ Backward (transpose) graph serialisation complete [$(bwg.pm.numpages) articles]")

println("✅ WikiGraph generation complete")
