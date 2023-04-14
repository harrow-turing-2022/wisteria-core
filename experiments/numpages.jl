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


function pageAnalysis(wg, isoPath, name)
    checkfile(isoPath)

    open(isoPath, "a") do f
        redirCount = 0
        linkedCount = 0
        sinkCount = 0
        totalCount = 0
    
        maxlks = 0
        maxpage = ""
        unlistmaxlks = 0
        unlistmaxpage = ""
    
        for i in ProgressBar(1:wg.pm.totalpages)

            if isRedir(wg.pm, i)
                redirCount += 1
            
            elseif length(wg.links[i]) > 0
                linkedCount += 1
                num = length(wg.links[i])
                
                if num > maxlks
                    maxlks = num
                    maxpage = wg.pm.id2title[i]
                end
    
                if num > unlistmaxlks && !occursin("index", lowercase(wg.pm.id2title[i])) && !occursin("list", lowercase(wg.pm.id2title[i]))
                    unlistmaxlks = num
                    unlistmaxpage = wg.pm.id2title[i]
                end
            
            else
                sinkCount += 1
                write(f, wg.pm.id2title[i], "\n")
            end

            totalCount += 1
        end

        expandStats(x) = "$(x)\t$(x * 100 / wg.pm.totalpages)\t$(x * 100 / wg.pm.numpages)"
        
        println("> $(name) <")
        println("\t\t\tcount\t% all\t% unredirected")
        println("| Total pages:\t\t$(expandStats(totalCount))")
        println("| Redirected pages:\t$(expandStats(redirCount))")
        println("| Linked pages:\t\t$(expandStats(linkedCount))")
        println("| Sink pages:\t$(expandStats(sinkCount))")
        println("| pm Total pages:\t$(wg.pm.totalpages)")
        println("| pm Unredirected:\t$(wg.pm.numpages)")
        println("| Max # links:\t$(maxlks) [ $(maxpage) ]")
        println("| Max # links in a non-list page: $(unlistmaxlks) [ $(unlistmaxpage) ]")
    end
end

pageAnalysis(fwg, "output/fwdSinks.txt", "Outbound Graph")
pageAnalysis(bwg, "output/bwdSinks.txt", "Inbound Graph")

checkfile("output/fwdTop1000.txt")
open("output/fwdTop1000.txt", "a") do f
    for (rank, id) in enumerate(fwdCountIDs[argmaxk(fwdCounts, 1000)])
        write(f, "$(rank) $(fwg.pm.id2title[id])\n")
    end
end

checkfile("output/bwdTop1000.txt")
open("output/bwdTop1000.txt", "a") do f
    for (rank, id) in enumerate(bwdCountIDs[argmaxk(bwdCounts, 1000)])
        write(f, "$(rank) $(bwg.pm.id2title[id])\n")
    end
end
