###############################################################################
#
#   Integers / Integer
#
###############################################################################

mutable struct Integers{T <: Integer} <: Ring
   function Integers{T}() where T <: Integer
      if haskey(IntegersID, T)
         z = IntegersID[T]::Integers{T}
      else 
         z = new{T}()
         IntegersID[T] = z
      end
      return z
   end
end

const IntegersID = Dict{DataType, Ring}()

###############################################################################
#
#   Unions of AbstactAlgebra abstract types and Julia types
#
###############################################################################

const RingElement = Union{RingElem, Integer}

