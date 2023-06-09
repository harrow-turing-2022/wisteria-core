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


using JLD2, ProgressBars


# Utility functions

function normalise(title::String)
    return replace(uppercasefirst(strip(title)), " " => "_")
end

checkfile(f) = ispath(f) && rm(f)

# Page management

mutable struct Pageman
    source::AbstractString
    id2title::Vector{String}
    title2id::Dict{String,Int32}
    redirs::Vector{Int32}
    numpages::Int32
    totalpages::Int32
    function Pageman(fpath::AbstractString)
        id2tt = readlines(fpath)[2:end]  # First line is "page_title"
        npg = length(id2tt)
        tt2id = Dict(id2tt .=> [i for i = 1:npg])
        rds = [i for i = 1:npg]
        return new(fpath, id2tt, tt2id, rds, npg, npg)
    end
end

function isRedir(
        pm::Pageman,
        id::Integer
    )
    return pm.redirs[id] != id
end

function notRedir(
        pm::Pageman,
        id::Integer
    )
    return pm.redirs[id] == id
end

function traceRedir!(
        pm::Pageman,
        id::Integer
    )
    intermediates = []
    red = pm.redirs[id]
    next = pm.redirs[red]

    while red != next
        push!(intermediates, red)
        red = pm.redirs[next]
        next = pm.redirs[red]
    end

    pm.redirs[id] = red
    for i in intermediates
        pm.redirs[i] = red
    end

    return red
end

function tie(
        pm::Pageman,
        srcId::Integer,
        trgId::Integer
    )
    if pm.redirs[srcId] != trgId
        if pm.redirs[srcId] == srcId
            pm.numpages -= 1
        end
        pm.redirs[srcId] = trgId
    end
end

function savepm(
        fpath::AbstractString,
        pm::Pageman
    )
    save(fpath, Dict("source" => pm.source, "numpages" => pm.numpages, "redirs" => pm.redirs))
end

function loadpm(fpath::AbstractString, titlesPath::AbstractString)
    bundle = load(fpath)
    pm = Pageman(titlesPath)
    pm.numpages = bundle["numpages"]
    pm.redirs = bundle["redirs"]
    return pm
end


# Link serialiation

function saveLinks(
        fpath::AbstractString,
        links::Vector{Vector{Pair{Int32, Int32}}},
        pm::Pageman
    )

    checkfile(fpath)

    open(fpath, "a") do f
        for i::Int32 in ProgressBar(eachindex(links))
            write(f, i)
            written = Int32[]
            for (t, w) in links[i]
                r = traceRedir!(pm, t)
                if !(r in written)
                    write(f, r, w, Int32(0))
                    push!(written, r)
                end
            end
            write(f, Int32(0))
        end
    end
end


function loadLinks(fpath::AbstractString, pm::Pageman; backwards::Bool=false)
    
    links = Vector{Pair{Int32, Int32}}[[] for _ = 1:pm.totalpages]

    open(fpath, "r") do f
        counter::Int32 = 1
        newline = true
        target = false
        weight = false
        delim = false
        cache::Int32 = 0

        for c in ProgressBar(readeach(f, Int32))
            if newline
                @assert c == counter "File is corrupted (counter error): counter is $(counter), file is $(c)"
                target = true
                newline = false
                
            elseif target
                if c == 0
                    counter += 1
                    newline = true
                else
                    @assert c > 0 "File is corrupted (target < 0)"
                    cache = c
                    weight = true
                end
                target = false
            
            elseif weight
                @assert c >= 0 "File is corrupted (weight <= 0)"
                
                trg = traceRedir!(pm, cache)
                if backwards
                    (counter => c) ∉ links[trg] && push!(links[trg], counter => c)
                else
                    (trg => c) ∉ links[counter] && push!(links[counter], trg => c)
                end
                
                delim = true
                weight = false

            elseif delim
                @assert c == 0 "File is corrupted (delim != 0)"
                target = true
                delim = false
            end
        end
    end

    return links

end


function saveLinksQuick(
        fpath::AbstractString,
        links::Vector{Vector{Pair{Int32, Int32}}}
    )

    checkfile(fpath)

    open(fpath, "a") do f
        for i::Int32 in ProgressBar(eachindex(links))
            for (t, w) in links[i]
                write(f, t)
            end
            write(f, Int32(0))
        end
    end
end


function saveLinksQuick(
        fpath::AbstractString,
        links::Vector{Vector{Int32}}
    )

    checkfile(fpath)

    open(fpath, "a") do f
        for i::Int32 in ProgressBar(eachindex(links))
            for t in links[i]
                write(f, t)
            end
            write(f, Int32(0))
        end
    end
end


function loadLinksQuick(fpath::AbstractString)
    links = Vector{Int32}[[]]

    open(fpath, "r") do f
        counter::Int32 = 1

        for c in ProgressBar(readeach(f, Int32))
            if c == 0
                counter += 1
                push!(links, [])
            else
                push!(links[counter], c)
            end
        end
    end

    return links
end
