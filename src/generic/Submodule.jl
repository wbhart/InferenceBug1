export Submodule

function Submodule(m::AbstractAlgebra.FPModule{T}, gens::Vector{S}) where {T <: RingElement, S <: AbstractAlgebra.FPModuleElem{T}}
      R = base_ring(m)
      gens = Vector{S}(undef, 0) # original may have generators that are zero
      M = Submodule{T}(m, gens, Vector{dense_matrix_type(T)}(undef, 0),
                       Vector{Int}(undef, 0), Vector{Int}(undef, 0))
      f = ModuleHomomorphism(M, m, matrix(R, 0, ngens(m), []))
      return M, f
end

