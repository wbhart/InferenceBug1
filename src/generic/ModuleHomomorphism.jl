export ModuleHomomorphism

function ModuleHomomorphism(M1::AbstractAlgebra.FPModule{T}, M2::AbstractAlgebra.FPModule{T}, m::AbstractAlgebra.MatElem{T}) where T <: RingElement
   return ModuleHomomorphism{T}(M1, M2, m)
end
