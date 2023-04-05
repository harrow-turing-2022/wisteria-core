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


using JLD2
using ProgressBars
include("utils.jl")

mutable struct Wikigraph
    pm::Pageman
    links::Vector{Vector{Pair{Int32, Int32}}}
    function Wikigraph(fpath::AbstractString)
        pm = Pageman(fpath)
        lk = [[] for _ = 1:pm.totalpages]
        return new(pm, lk)
    end
    function Wikigraph(pm::Pageman, lk::Vector{Vector{Pair{Int32, Int32}}})
        return new(pm, lk)
    end
end

function link(
        wg::Wikigraph,
        srcID::Integer,
        trgID::Integer,
        weight::Integer
    )
    push!(wg.links[srcID], trgID => weight)
end

function savewg(
        fdir::AbstractString,
        wg::Wikigraph
    )
    if !ispath(fdir) 
        mkpath(fdir)
    end
    savepm(joinpath(fdir, "pm.jld2"), wg.pm)
    saveLinks(joinpath(fdir, "links.ria"), wg.links, wg.pm)
end

function loadwg(fdir::AbstractString, titlesPath::AbstractString; backwards::Bool=false)
    pm = loadpm(joinpath(fdir, "pm.jld2"), titlesPath)
    if backwards
        links = loadLinks(joinpath(fdir, "links.ria"), pm; backwards=true)
    else
        links = loadLinks(joinpath(fdir, "links.ria"), pm)
    end
    return Wikigraph(pm, links)
end

function wgIntegrity(fdir::AbstractString)
    return ispath(joinpath(fdir, "pm.jld2")) && ispath(joinpath(fdir, "links.ria"))
end

function toEdgeTxt(
        fpath::AbstractString,
        wg::Wikigraph;
        uniformWeight=false,
        son="",
        delim="\t",
        eol="\n"
    )
    if ispath(fpath)
        rm(fpath)
    end

    open(fpath, "a") do f
        for srcID in ProgressBar(1:wg.pm.totalpages)
            if notRedir(wg.pm, srcID)
                for (_trgID, w) in wg.links[srcID]
                    trgID = traceRedir!(wg.pm, _trgID)
                    if uniformWeight
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(eol)")
                    else 
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(delim)$(w)$(eol)")
                    end
                end
            end
        end
    end
end

function toTitleTxt(
        fpath::AbstractString,
        wg::Wikigraph;
        son="",
        delim="\t",
        eol="\n"
    )
    if ispath(fpath)
        rm(fpath)
    end

    open(fpath, "a") do f
        for srcID in ProgressBar(1:wg.pm.totalpages)
            if notRedir(wg.pm, srcID)
                write(f, "$(son)$(srcID)$(delim)$(wg.pm.id2title[srcID])$(eol)")
            end
        end
    end
end

function toNCOL(
        fpath::AbstractString,
        wg::Wikigraph;
        uniformWeight=false,
        son="v",
        delim=" ",
        eol="\n"
    )
    if ispath(fpath)
        rm(fpath)
    end

    open(fpath, "a") do f
        for srcID in ProgressBar(1:wg.pm.totalpages)
            if notRedir(wg.pm, srcID)
                for (_trgID, w) in wg.links[srcID]
                    trgID = traceRedir!(wg.pm, _trgID)

                    if (srcID in wg.links[trgID]) && srcID < trgID
                        continue
                    elseif srcID == trgID
                        continue
                    end

                    if uniformWeight
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(eol)")
                    else 
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(delim)$(w)$(eol)")
                    end
                end
            end
        end
    end
end

function toLGL(
        fpath::AbstractString,
        wg::Wikigraph;
        uniformWeight=false,
        son="v",
        delim=" ",
        eol="\n"
    )
    if ispath(fpath)
        rm(fpath)
    end

    open(fpath, "a") do f
        for srcID in ProgressBar(1:wg.pm.totalpages)
            if notRedir(wg.pm, srcID)

                write(f, "# $(son)$(srcID)$(eol)")

                for (_trgID, w) in wg.links[srcID]
                    trgID = traceRedir!(wg.pm, _trgID)

                    if (srcID in wg.links[trgID]) && srcID < trgID
                        continue
                    elseif srcID == trgID
                        continue
                    end

                    if uniformWeight
                        write(f, "$(son)$(trgID)$(eol)")
                    else 
                        write(f, "$(son)$(trgID)$(delim)$(w)$(eol)")
                    end
                end
            end
        end
    end
end

function toCosmo(
        fpath::AbstractString,
        wg::Wikigraph;
        uniformWeight=false,
        son="",
        delim=";",
        eol="\n"
    )
    if ispath(fpath)
        rm(fpath)
    end

    open(fpath, "a") do f
        if uniformWeight
            write(f, "source;target$(eol)")
        else
            write(f, "source;target;value$(eol)")
        end

        for srcID in ProgressBar(1:wg.pm.totalpages)
            if notRedir(wg.pm, srcID)
                for (_trgID, w) in wg.links[srcID]
                    trgID = traceRedir!(wg.pm, _trgID)

                    if uniformWeight
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(eol)")
                    else 
                        write(f, "$(son)$(srcID)$(delim)$(son)$(trgID)$(delim)$(w)$(eol)")
                    end
                end
            end
        end
    end
end
