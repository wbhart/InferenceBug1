domain(f::AbstractAlgebra.Map) = get_field(f, :domain)

function check_composable(a::AbstractAlgebra.Map{D, U}, b::AbstractAlgebra.Map{U, C}) where {D, U, C}
   codomain(a) != domain(b) && error("Incompatible maps")
end

function compose(f::AbstractAlgebra.Map(AbstractAlgebra.FunctionalMap){D, U}, g::AbstractAlgebra.Map(AbstractAlgebra.FunctionalMap){U, C}) where {D, U, C}
   check_composable(f, g)
   return FunctionalCompositeMap(f, g)
end
