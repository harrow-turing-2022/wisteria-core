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


using EzXML
using ProgressBars
include("wikigraph.jl")


function hmean(freqs)
    num = 0
    rec = 0
    for f in freqs
        num += 1
        rec += 1 / f
    end
    return ceil(num / rec)
end

function strength(
        text::AbstractString,
        phrase::AbstractString
    )
    return 1

    #=
    phrase = lowercase(phrase)
    words = [i.match for i in eachmatch(r"[a-z']+", phrase)]
    numwords = length(words)
    
    if numwords == 0
        return length(findall(phrase, text))
    end
    
    return hmean([length(findall(w, text)) for w in words]);
    =#
end

function mineLinks(
        text::AbstractString,
        lowertext::AbstractString,
        wiki_namespaces::Vector{String}
    )
    linkTargets = AbstractString[]
    linkWeights = Integer[]

    len = length(text)

    inlink = false
    last = ""
    cache = ""
    counter = 1

    for i in eachindex(text)
        if counter > (len - 3)
            break
        end

        c = text[i:i]

        if inlink
            if c in ("|", "#") || last*c == "]]"
                title = normalise(cache)
                if !(title in linkTargets)
                    push!(linkTargets, title)
                    push!(linkWeights, strength(lowertext, cache))
                end

                inlink = false
                last = ""
                cache = ""
            
            elseif last == "]"
                cache *= "]" * c
            elseif c != "]"
                cache *= c
            end

            if cache in wiki_namespaces
                inlink = false
                last = ""
                cache = ""
            end

        elseif last*c == "[["
                inlink = true
        end

        last = c
        counter += 1
    end

    return linkTargets .=> linkWeights
    #= Above equivalent to:
        [ linkTargets[0] => linkWeights[0],
          linkTargets[1] => linkWeights[1],
          ...,
          linkTargets[n] => linkWeights[n] ]
    =#
end


function mineXML(
        xmlPath::AbstractString,
        wg::Wikigraph,
        wgDir::AbstractString,
        logPath::AbstractString,
        numPages::Integer
    )
    println("\nTotal page count: $(wg.pm.totalpages)")

    println("\nReading XML document")
    @time doc = readxml(xmlPath)
    xmlns = namespace(doc.root)

    wiki_namespaces = String[]
    for i in findall("/x:mediawiki/x:siteinfo/x:namespaces/x:namespace", doc.root, ["x" => xmlns])
        if i.content != ""
            push!(wiki_namespaces, normalise(i.content) * ":")
            push!(wiki_namespaces, ":" * normalise(i.content) * ":")
        end
    end

    println("\nWikipedia namepsaces: $(wiki_namespaces)\n")

    open(logPath, "a") do logs
        
        counter = 0
        numlinks = []
        iter = ProgressBar(eachelement(doc.root))

        for ele in iter
            if ele.name != "page"
                continue
            end

            children = elements(ele)
    
            @assert (children[1].name == "title") "Title not first child element"
            title = normalise(children[1].content)

            if !haskey(wg.pm.title2id, title) ||                                # Not an article
               wg.pm.redirs[wg.pm.title2id[title]] != wg.pm.title2id[title] ||  # Is redirected
               length(wg.links[wg.pm.title2id[title]]) != 0                     # Already mined
               
                # println("========== SKIPPED $(title) ==========\n")

            elseif children[end-1].name == "redirect"
                redir = normalise(children[end - 1]["title"])
                if haskey(wg.pm.title2id, redir)
                    tie(wg.pm, wg.pm.title2id[title], wg.pm.title2id[redir])
                end
                # println("========== REDIRECTED $(title) ==========\n")
            
            else
                @assert (children[end].name == "revision") "Revision not last child element"
                revision_children = elements(children[end])
                @assert (revision_children[end-1].name == "text") 
                    "Text not second last revision child element"
    
                text = revision_children[end-1].content
                lowertext = lowercase(text)
                lks = mineLinks(text, lowertext, wiki_namespaces)
    
                title_id = wg.pm.title2id[title]
                for (t, w) in lks
                    try
                        link(wg, title_id, wg.pm.title2id[t], w)
                    catch err
                        write(logs, "$(title)\t$(t)\n")
                        # println("Title error! ", err)
                    end
                end
                push!(numlinks, length(wg.links[wg.pm.title2id[title]]))
    
                # println("========== COMPLETED $(title) ==========\n")
            end
            
            counter += 1
            set_description(iter, "$(counter)/$(numPages)")
        end

        printlog(s) = (write(logs, s); println(s))
        printlog("\nAverage number of links: $(trunc(sum(numlinks)/length(numlinks), digits=3))\n")
        printlog("Pages with links: $(length(numlinks))\n")
        printlog("Number of pages (not counting redirects): $(wg.pm.numpages)")
    end

    println("\nSaving Wikigraph")
    @time savewg(wgDir, wg)

    return wg
end
