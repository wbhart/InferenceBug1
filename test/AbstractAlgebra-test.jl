function rand_homomorphism(M::AbstractAlgebra.FPModule{T}, vals...) where T <: RingElement
   F = FreeModule(ZZ, 5)
   S = MatrixSpace(ZZ, 5, 3)
   mat = rand(S, vals...)
   f = ModuleHomomorphism(F, M, mat)
   gens1 = [rand(F, vals...) for j in 1:3]
   S, g = Submodule(F, gens1)
   hom1 = compose(g, f)
   return S, hom1
end

function test_module()

         M = FreeModule(ZZ, 3)
         S, f = rand_homomorphism(M, -10:10)

   println("done")
end
