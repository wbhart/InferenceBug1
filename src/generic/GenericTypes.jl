###############################################################################
#
#   MatSpace / Mat
#
###############################################################################

# All MatSpaceElem's and views thereof
abstract type Mat{T} <: MatElem{T} end

# not really a mathematical ring
mutable struct MatSpace{T <: RingElement} <: AbstractAlgebra.MatSpace{T}
   nrows::Int
   ncols::Int
   base_ring::Ring

   function MatSpace{T}(R::Ring, r::Int, c::Int, cached::Bool = true) where T <: RingElement
      if cached && haskey(MatDict, (R, r, c))
         return MatDict[R, r, c]::MatSpace{T}
      else
         z = new{T}(r, c, R)
         if cached
            MatDict[R, r, c] = z
         end
         return z
      end
   end
end

const MatDict = Dict{Tuple{Ring, Int, Int}, MatSpace}()

mutable struct MatSpaceElem{T <: RingElement} <: Mat{T}
   entries::Array{T, 2}
   base_ring::Ring

   function MatSpaceElem{T}(A::Array{T, 2}) where T <: RingElement
      return new{T}(A)
    end

   function MatSpaceElem{T}(A::AbstractArray{T, 2}) where T <: RingElement
      return new{T}(Array(A))
   end

   function MatSpaceElem{T}(r::Int, c::Int, A::Array{T, 1}) where T <: RingElement
      t = Array{T}(undef, r, c)
      for i = 1:r
         for j = 1:c
            t[i, j] = A[(i - 1) * c + j]
         end
      end
      return new{T}(t)
   end
end

###############################################################################
#
#   Map type functions
#
###############################################################################

Map(::Type{T}) where T <: AbstractAlgebra.Map = supertype(T)
Map(::Type{S}) where S <: AbstractAlgebra.SetMap = Map{D, C, S, T} where {D, C, T}

###############################################################################
#
#   FunctionalMap
#
###############################################################################

mutable struct FunctionalMap{D, C} <: AbstractAlgebra.Map{D, C, AbstractAlgebra.FunctionalMap, FunctionalMap}
    domain::D
    codomain::C
    image_fn::Function
end

###############################################################################
#
#   FunctionalCompositeMap
#
###############################################################################

mutable struct FunctionalCompositeMap{D, C} <: AbstractAlgebra.Map{D, C, AbstractAlgebra.FunctionalMap, FunctionalCompositeMap}
   domain::D
   codomain::C
   map1::AbstractAlgebra.Map
   map2::AbstractAlgebra.Map
   fn_cache::Function

   function FunctionalCompositeMap(map1::Map(AbstractAlgebra.FunctionalMap){D, U}, map2::Map(AbstractAlgebra.FunctionalMap){U, C}) where {D, U, C}
      return new{D, C}(domain(map1), codomain(map2), map1, map2)
   end
end

###############################################################################
#
#   FreeModule/free_module_elem
#
###############################################################################

mutable struct FreeModule{T <: RingElement} <: AbstractAlgebra.FPModule{T}
   rank::Int
   base_ring::Ring

   function FreeModule{T}(R::Ring, rank::Int, cached::Bool = true) where T <: RingElement
      if cached && haskey(FreeModuleDict, (R, rank))
         return FreeModuleDict[R, rank]::FreeModule{T}
      else
         z = new{T}(rank, R)
         if cached
            FreeModuleDict[R, rank] = z
         end
         return z
      end
   end
end

const FreeModuleDict = Dict{Tuple{Ring, Int}, FreeModule}()

mutable struct free_module_elem{T <: RingElement} <: AbstractAlgebra.FPModuleElem{T}
    v::AbstractAlgebra.MatElem{T}
    parent::FreeModule{T}

    function free_module_elem{T}(v::AbstractAlgebra.MatElem{T}) where T <: RingElement
       z = new{T}(v)
    end
end

###############################################################################
#
#   ModuleHomomorphism
#
###############################################################################

mutable struct ModuleHomomorphism{T <: RingElement} <: AbstractAlgebra.Map{AbstractAlgebra.FPModule{T}, AbstractAlgebra.FPModule{T}, AbstractAlgebra.FunctionalMap, ModuleHomomorphism}

   domain::AbstractAlgebra.FPModule{T}
   codomain::AbstractAlgebra.FPModule{T}
   matrix::AbstractAlgebra.MatElem{T}
   image_fn::Function

   function ModuleHomomorphism{T}(D::AbstractAlgebra.FPModule{T}, C::AbstractAlgebra.FPModule{T}, m::AbstractAlgebra.MatElem{T}) where T <: RingElement
      z = new(D, C, m, x::AbstractAlgebra.FPModuleElem{T} -> C(x.v*m))
   end
end

###############################################################################
#
#   Submodule/submodule_elem
#
###############################################################################

mutable struct Submodule{T <: RingElement} <: AbstractAlgebra.FPModule{T}
   m::AbstractAlgebra.FPModule{T}
   gens::Vector{<:AbstractAlgebra.FPModuleElem{T}}
   rels::Vector{<:AbstractAlgebra.MatElem{T}}
   gen_cols::Vector{Int}
   pivots::Vector{Int}
   base_ring::Ring
   map::ModuleHomomorphism{T}

   function Submodule{T}(M::AbstractAlgebra.FPModule{T}, gens::Vector{<:AbstractAlgebra.FPModuleElem{T}}, rels::Vector{<:AbstractAlgebra.MatElem{T}}, gen_cols::Vector{Int}, pivots::Vector{Int}) where T <: RingElement
      z = new{T}(M, gens, rels, gen_cols, pivots, base_ring(M))
   end
end

mutable struct submodule_elem{T <: RingElement} <: AbstractAlgebra.FPModuleElem{T}
   v::AbstractAlgebra.MatElem{T}
   parent::Submodule{T}

   function submodule_elem{T}(m::AbstractAlgebra.FPModule{T}, v::AbstractAlgebra.MatElem{T}) where T <: RingElement
      z = new{T}(v, m)
   end
end

