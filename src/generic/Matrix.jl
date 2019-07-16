base_ring(a::AbstractAlgebra.MatSpace{T}) where {T <: RingElement} = a.base_ring::parent_type(T)

function rand(S::AbstractAlgebra.MatSpace, v...)
   M = S()
   R = base_ring(S)
   for i = 1:nrows(M)
      for j = 1:ncols(M)
         M[i, j] = rand(R, v...)
      end
   end
   return M
end

function (a::MatSpace{T})() where {T <: RingElement}
   R = base_ring(a)
   entries = Array{T}(undef, a.nrows, a.ncols)
   for i = 1:a.nrows
      for j = 1:a.ncols
         entries[i, j] = zero(R)
      end
   end
   z = MatSpaceElem{T}(entries)
   z.base_ring = R
   return z
end

function MatrixSpace(R::AbstractAlgebra.Ring, r::Int, c::Int, cached::Bool = true)
   T = elem_type(R)
   return MatSpace{T}(R, r, c, cached)
end

