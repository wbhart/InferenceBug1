export FreeModule, free_module_elem

base_ring(M::FreeModule{T}) where T <: RingElement = M.base_ring::parent_type(T)

ngens(M::FreeModule{T}) where T <: RingElement = M.rank

function FreeModule(R::Ring, rank::Int; cached::Bool = true)
   T = elem_type(R)
   return FreeModule{T}(R, rank, cached)
end

