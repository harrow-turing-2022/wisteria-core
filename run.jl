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
include("parser.jl")
include("wikigraph.jl")

function dunzip(fname)
    run(`curl https://dumps.wikimedia.org/enwiki/20230101/$fname --output $fname`)
    run(`7z x $fname -odata`)
    rm(fname)
end

files = [String(strip(i)) for i in split(read("data/multistream-urls.txt", String), "\n")]
start = length(ARGS) == 0 ? 1 : parse(Int64, ARGS[1])

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
    
    # Loads wg from `graph/`, mines XML to update wg, and saves it back into `graph`
    wg = mineXML(
        "data/$(xmlname)",
        "graph/",
        "data/enwiki-20230101-all-titles-in-ns0",
        "logs/$(i)/title_errors.txt",
        numpages
    )

    rm("data/$(xmlname)")
end

fwg = loadwg("graph/", "data/enwiki-20230101-all-titles-in-ns0")
savewgQuick("graph/", fwg)

bwg = loadwg("graph/", "data/enwiki-20230101-all-titles-in-ns0"; backwards=true)
savewg("backgraph/", bwg)
savewgQuick("backgraph/", bwg)
