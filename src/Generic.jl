module Generic

import LinearAlgebra: det, norm,
                      nullspace, rank, transpose!, hessenberg

using Markdown, Random, InteractiveUtils

import Base: Array, checkbounds,
             convert, cmp, dec, deepcopy,
             deepcopy_internal, div, divrem,
             exponent, gcd, gcdx, getindex, hash, hcat, intersect, inv,
             isequal, isless, iszero,
             length, mod,
             one, parent,
             rand, Rational, rem,
             setindex!, show, similar, sign, size, string,
             typed_hvcat, typed_hcat, vcat, zero, zeros, +, -, *, ==, ^,
             &, |, <<, >>, ~, <=, >=, <, >, //, /, !=

import Base: isone

import AbstractAlgebra: Integers, Ring, RingElem,
       RingElement, Map, promote_rule

using AbstractAlgebra

include("generic/GenericTypes.jl")

include("generic/Matrix.jl")

include("generic/FreeModule.jl")

include("generic/Submodule.jl")

include("generic/ModuleHomomorphism.jl")

include("generic/Map.jl")

end # generic
