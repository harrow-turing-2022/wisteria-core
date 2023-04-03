# Wisteria Core

_Project Wisteria's core graph generation, serialisation, and analysis tools_

> Table of contents:
>
> - [Getting Started](#getting-started)
> - [Important Notes](#important-notes)
> - [Reusing Graphs](#reusing-graphs)
> - [File Structure](#file-structure)
> - [Wikigraph Docs](#wikigraph-docs)

## Getting Started

1. Make sure you have Julia installed and accessible via the command line. If not, [install Julia](https://julialang.org/downloads/). This code has been tested with Julia 1.7.3.

2. If Windows, make sure you have the [`curl`](https://curl.se/windows/) and [`7z`](https://www.7-zip.org/download.html) commands available on command line. To add the `7z` command provided by 7zip, download [7zr.exe](https://www.7-zip.org/a/7zr.exe), rename it 7z.exe, and add it to PATH.

3. Open your Julia terminal and run the setup script to get started:

   ```bash
   julia setup.jl
   ```

   Internet connection is required to automatically download and extract the necessary Wikipedia dump files for Wisteria to work correctly.

4. to extract link relationships between Wikipedia articles, run the command:

   ```bash
   julia run.jl
   ```

   An Internet connection is required as Wikipedia dumps will be downloaded, unzipped, and deleted on the fly to save storage space.

   - If, for any reason, your link extraction is incomplete, you can go into `./logs` to find out the last complete parsing of a data dump (there are 63 dumps to be parsed in total). Each log file is saved under the index of its dump (i.e. logs for dump index 1 is stored under `./logs/1`).

     A completely parsed dump will generate something like the following at the end of `title_errors.txt`:

     ```
     Average number of links: 34.715
     Pages with links: 16226
     Number of pages (not counting redirects): 15704852
     ```

     If this is not generated, then parsing of that dump is incomplete, and you can instruct Wisteria to start parsing there.

     For example, suppose dump 21 is incomplete. To pick up progress from there, simply run

     ```bash
     julia run.jl 21
     ```

5. We use `PyPlot.jl` to generate graphs for our experiments. This relies on an existing Python interpreter with `matplotlib` installed. To run our experiments, please first [install Python](https://www.python.org/downloads/) and add the matplotlib package using `pip install matplotlib`.

6. To run `experiments/indexStats.jl`, you will need the GitHub version of `Pingouin.jl`. Enter package manager mode in Julia by pressing`]`, and run:
```
add https://github.com/clementpoiret/Pingouin.jl.git
```

## Important Notes

Since the `Pageman` object of our system uses a relative path to reference the list of titles on Wikipedia, please make sure that:

- The file `enwiki-20230101-all-titles-in-ns0` is present in `./data` (this should be done automatically by `setup.jl`)
- You are running any Julia scripts from the root of this repository (i.e. where you can see `explore.jl`, `parser.jl`, `./data`, `./graph`, etc.)

Otherwise, things might not work!

## Reusing Graphs

You can easily browse and reuse the graphs generated by someone else. Just place `links.ria` and `pm.jld2` into the `./graph` directory, and you should be able to load, serialise, and explore the graph without any problems.

## File Structure

- [`parser.jl`](./parser.jl): Parses XML files for links and connection strengths (under development).
- [`run.jl`](./run.jl): Downloads all required Wikipedia dump files, extracts links, and stores graph in `./graph`, with a list of unidentifiable titles stored in `./logs`.
- [`serialise.jl`](./serialise.jl): Serialises graph into `./ser` with all supported file formats.
- [`setup.jl`](./setup.jl): Installs Julia packages, creates directories, checks commands, downloads data... If this runs without failure, you should be able to run the rest of Wisteria.
- [`utils.jl`](./utils.jl): Utilities for saving links in the `.RIA` file format; defines the `Pageman` (page management) object for handling page IDs, titles, and redirects.
- [`wikigraph.jl`](./wikigraph.jl): Defines the `Wikigraph` object for capturing links and relationships between Wikipedia pages; functions to serialise `Wikigraph` into various file formats.

## Wikigraph Docs

To load a Wikigraph:

```julia
# Include wisteria graph loading functions
include("wikigraph.jl")

# Load a Wikigraph object
wg = loadwg("path/to/graph-directory", "path/to/all-titles-file")
# E.g. wg = loadwg("graph/", "data/enwiki-20230101-all-titles-in-ns0")
```

Attributes of a `Wikigraph` object:

- `wg.pm`::`Pageman`

  Attributes of a `Pageman` object:

  - `id2title`::`Vector{String}`

    A vector mapping from `Int32` IDs to `String` titles

  - `title2id`::`Dict{String,Int32}`

    A vector mapping from `String` titles to `Int32` IDs

  - `redirs`::`Vector{Int32}`

    A vector mapping from `Int32` IDs to its redirected `Int32` ID (maps back to the same ID if it is not redirected)

  - `numpages`::`Int32`

    Number of non-redirected pages

  - `totalpages`::`Int32`

    Total number of pages (including redirects)

- `wg.links`::`Vector{Vector{Pair{Int32, Int32}}}`

  A vector mapping from `Int32` IDs to a vector of `Int32` IDs connected to it.

Tying the above together, the following is a sample code to extract all links and weights of node ID 1:

```julia
# Keep track of linked IDs
linked = Int32[]

# Loop through all IDs and weights connected to node 1
for (id, weight) in wg.links[1]

    # Handle redirected pages
    redirected_id = wg.pm.redirs[id]

    # Check if ID is already linked
    if !(redirected_id in linked)

        # If not, add it to the vector of linked IDs
        push!(linked, redirected_id)

        # Print out ID and weight
        println("Connected to ", redirected_id, " with weight ", weight)
    end
end
```

## License

All code in this repository is licensed under the GNU General Public License version 3.