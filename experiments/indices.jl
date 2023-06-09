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


α(indeg, outdeg) = indeg - outdeg
ϵ(indeg, outdeg) = indeg / outdeg
λ(indeg, outdeg) = (indeg - outdeg) / outdeg
χ(indeg, outdeg) = log(indeg) / log(outdeg)
κ(indeg, outdeg) = log(indeg / outdeg)
κ_prime(indeg, outdeg) = κ(indeg, outdeg) * log(indeg + outdeg)
