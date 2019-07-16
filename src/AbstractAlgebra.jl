module AbstractAlgebra

using InteractiveUtils

export RingElement

export MatElem

export MatSpace

export ZZ

include("AbstractTypes.jl")

###############################################################################
#
#   Julia types
#
###############################################################################

include("julia/JuliaTypes.jl")

###############################################################################
#
#   Generic submodule
#
###############################################################################

include("Generic.jl")

import .Generic: compose

export compose

function divrem(a::T, b::T) where T
  return Base.divrem(a, b)
end

function MatrixSpace(R::Ring, r::Int, c::Int, cached::Bool = true)
   Generic.MatrixSpace(R, r, c, cached)
end

function FreeModule(R::Ring, rank::Int; cached::Bool = true)
   Generic.FreeModule(R, rank; cached=cached)
end

function Submodule(m::FPModule{T}, gens::Vector{<:FPModuleElem{T}}) where T <: RingElement
   Generic.Submodule(m, gens)
end

function Submodule(m::FPModule{T}, gens::Vector{Any}) where T <: RingElement
   Generic.Submodule(m, gens)
end

function Submodule(m::FPModule{T}, subs::Vector{<:Generic.Submodule{T}}) where T <: RingElement
   Generic.Submodule(m, subs)
end

function Submodule(m::FPModule{T}, subs::Vector{<:Generic.Submodule{U}}) where {T <: RingElement, U <: Any}
   Generic.Submodule(m, subs)
end

function ModuleHomomorphism(M1::FPModule, M2::FPModule, m::MatElem)
   Generic.ModuleHomomorphism(M1, M2, m)
end

export MatrixSpace,
       FreeModule, ModuleHomomorphism, Submodule

export Generic

###############################################################################
#
#   Load Groups/Rings/Fields etc.
#
###############################################################################

include("Rings.jl")

###############################################################################
#
#   Set domain for ZZ
#
###############################################################################

ZZ = JuliaZZ

end # module
