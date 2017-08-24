###############################################################################
#
#   AbsSeries.jl : Power series over rings, capped relative precision
#
###############################################################################

export GenAbsSeries, GenAbsSeriesRing, O, valuation, exp,
       precision, max_precision, set_prec!

###############################################################################
#
#   Data type and parent object methods
#
###############################################################################

doc"""
    O{T <: RingElement}(a::AbsSeriesElem{T})
> Returns $0 + O(x^\mbox{deg}(a))$. Usually this function is called with $x^n$
> as parameter. Then the function returns the power series $0 + O(x^n)$, which
> can be used to set the precision of a power series when constructing it.
"""
function O(a::AbsSeriesElem{T}) where T <: RingElement
   if iszero(a)
      return deepcopy(a)    # 0 + O(x^n)
   end
   prec = length(a) - 1
   prec < 0 && throw(DomainError())
   return parent(a)(Array{T}(0), 0, prec)
end

parent_type(::Type{GenAbsSeries{T}}) where {T <: RingElement} = GenAbsSeriesRing{T}

elem_type(::Type{GenAbsSeriesRing{T}}) where {T <: RingElement} = GenAbsSeries{T}

###############################################################################
#
#   Basic manipulation
#
###############################################################################

length(x::AbsSeriesElem) = x.length

precision(x::AbsSeriesElem) = x.prec

doc"""
    max_precision(R::SeriesRing)
> Return the maximum absolute precision of power series in the given power
> series ring.
"""
max_precision(R::GenAbsSeriesRing) = R.prec_max

function normalise(a::GenAbsSeries, len::Int)
   while len > 0 && iszero(a.coeffs[len])
      len -= 1
   end
   return len
end

function coeff(a::GenAbsSeries, n::Int)
   n < 0  && throw(DomainError())
   return n >= length(a) ? zero(base_ring(a)) : a.coeffs[n + 1]
end

doc"""
    gen{T <: RingElement}(R::GenAbsSeriesRing{T})
> Return the generator of the power series ring, i.e. $x + O(x^n)$ where
> $n$ is the precision of the power series ring $R$.
"""
function gen(R::GenAbsSeriesRing{T}) where T <: RingElement
   S = base_ring(R)
   return R([S(0), S(1)], 2, max_precision(R))
end

doc"""
    iszero(a::SeriesElem)
> Return `true` if the given power series is arithmetically equal to zero to
> its current precision, otherwise return `false`.
"""
iszero(a::SeriesElem) = length(a) == 0

doc"""
    isone(a::GenAbsSeries)
> Return `true` if the given power series is arithmetically equal to one to
> its current precision, otherwise return `false`.
"""
function isone(a::GenAbsSeries)
   return (length(a) == 1 && isone(coeff(a, 0))) || precision(a) == 0
end

doc"""
    isgen(a::GenAbsSeries)
> Return `true` if the given power series is arithmetically equal to the
> generator of its power series ring to its current precision, otherwise return
> `false`.
"""
function isgen(a::GenAbsSeries)
   return (valuation(a) == 1 && length(a) == 2 && isone(coeff(a, 1))) ||
           precision(a) == 0
end

doc"""
    isunit(a::AbsSeriesElem)
> Return `true` if the given power series is arithmetically equal to a unit,
> i.e. is invertible, otherwise return `false`.
"""
isunit(a::AbsSeriesElem) = valuation(a) == 0 && isunit(coeff(a, 0))

doc"""
    valuation(a::AbsSeriesElem)
> Return the valuation of the given power series, i.e. the degree of the first
> nonzero term (or the precision if it is arithmetically zero).
"""
function valuation(a::AbsSeriesElem)
   for i = 1:length(a)
      if !iszero(coeff(a, i - 1))
         return i - 1
      end
   end
   return precision(a)
end

function deepcopy_internal(a::GenAbsSeries{T}, dict::ObjectIdDict) where {T <: RingElement}
   coeffs = Array{T}(length(a))
   for i = 1:length(a)
      coeffs[i] = deepcopy(coeff(a, i - 1))
   end
   return parent(a)(coeffs, length(a), precision(a))
end

###############################################################################
#
#   AbstractString I/O
#
###############################################################################

function show(io::IO, x::AbsSeriesElem)
   len = length(x)

   if len == 0
      print(io, zero(base_ring(x)))
   else
      coeff_printed = false
      for i = 0:len - 1
         c = coeff(x, i)
         if !iszero(c)
            if coeff_printed
               print(io, "+")
            end
            if i != 0
               if !isone(c)
                  print(io, "(")
                  print(io, c)
                  print(io, ")")
                  if i != 0
                     print(io, "*")
                  end
               end
               print(io, string(var(parent(x))))
               if i != 1
                  print(io, "^")
                  print(io, i)
               end
            else
               print(io, c)
            end
            coeff_printed = true
         end
      end
   end
   print(io, "+O(", string(var(parent(x))), "^", precision(x), ")")
end

###############################################################################
#
#   Unary operators
#
###############################################################################

doc"""
    -(a::AbsSeriesElem)
> Return $-a$.
"""
function -(a::AbsSeriesElem)
   len = length(a)
   z = parent(a)()
   set_prec!(z, precision(a))
   fit!(z, len)
   for i = 1:len
      z = setcoeff!(z, i - 1, -coeff(a, i - 1))
   end
   return z
end

###############################################################################
#
#   Binary operators
#
###############################################################################

doc"""
    +{T <: RingElement}(a::AbsSeriesElem{T}, b::AbsSeriesElem{T})
> Return $a + b$.
"""
function +(a::AbsSeriesElem{T}, b::AbsSeriesElem{T}) where {T <: RingElement}
   check_parent(a, b)
   lena = length(a)
   lenb = length(b)
   prec = min(precision(a), precision(b))
   lena = min(lena, prec)
   lenb = min(lenb, prec)
   lenz = max(lena, lenb)
   z = parent(a)()
   fit!(z, lenz)
   set_prec!(z, prec)
   i = 1
   while i <= min(lena, lenb)
      z = setcoeff!(z, i - 1, coeff(a, i - 1) + coeff(b, i - 1))
      i += 1
   end
   while i <= lena
      z = setcoeff!(z, i - 1, coeff(a, i - 1))
      i += 1
   end
   while i <= lenb
      z = setcoeff!(z, i - 1, coeff(b, i - 1))
      i += 1
   end
   set_length!(z, normalise(z, i - 1))
   return z
end

doc"""
    -{T <: RingElement}(a::AbsSeriesElem{T}, b::AbsSeriesElem{T})
> Return $a - b$.
"""
function -(a::AbsSeriesElem{T}, b::AbsSeriesElem{T}) where {T <: RingElement}
   check_parent(a, b)
   lena = length(a)
   lenb = length(b)
   prec = min(precision(a), precision(b))
   lena = min(lena, prec)
   lenb = min(lenb, prec)
   lenz = max(lena, lenb)
   z = parent(a)()
   fit!(z, lenz)
   set_prec!(z, prec)
   i = 1
   while i <= min(lena, lenb)
      z = setcoeff!(z, i - 1, coeff(a, i - 1) - coeff(b, i - 1))
      i += 1
   end
   while i <= lena
      z = setcoeff!(z, i - 1, coeff(a, i - 1))
      i += 1
   end
   while i <= lenb
      z = setcoeff!(z, i - 1, -coeff(b, i - 1))
      i += 1
   end
   set_length!(z, normalise(z, i - 1))
   return z
end

doc"""
    *{T <: RingElement}(a::AbsSeriesElem{T}, b::AbsSeriesElem{T})
> Return $a\times b$.
"""
function *(a::AbsSeriesElem{T}, b::AbsSeriesElem{T}) where {T <: RingElement}
   check_parent(a, b)

   lena = length(a)
   lenb = length(b)

   aval = valuation(a)
   bval = valuation(b)

   prec = min(precision(a) + bval, precision(b) + aval)
   prec = min(prec, max_precision(parent(a)))

   lena = min(lena, prec)
   lenb = min(lenb, prec)

   if lena == 0 || lenb == 0
      return parent(a)(Array{T}(0), 0, prec)
   end
   t = base_ring(a)()
   lenz = min(lena + lenb - 1, prec)
   d = Array{T}(lenz)
   for i = 1:min(lena, lenz)
      d[i] = coeff(a, i - 1)*coeff(b, 0)
   end
   if lenz > lena
      for j = 2:min(lenb, lenz - lena + 1)
          d[lena + j - 1] = coeff(a, lena - 1)*coeff(b, j - 1)
      end
   end
   for i = 1:lena - 1
      if lenz > i
         for j = 2:min(lenb, lenz - i + 1)
            t = mul!(t, coeff(a, i - 1), coeff(b, j - 1))
            d[i + j - 1] = addeq!(d[i + j - 1], t)
         end
      end
   end
   z = parent(a)(d, lenz, prec)
   set_length!(z, normalise(z, lenz))
   return z
end

###############################################################################
#
#   Ad hoc binary operators
#
###############################################################################

doc"""
    *{T <: RingElem}(a::T, b::AbsSeriesElem{T})
> Return $a\times b$.
"""
function *(a::T, b::AbsSeriesElem{T}) where {T <: RingElem}
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   set_prec!(z, precision(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   set_length!(z, normalise(z, len))
   return z
end

doc"""
    *{T <: Union{Int, BigInt}}(a::Rational{T}, b::AbsSeriesElem{Rational{T}})
> Return $a\times b$.
"""
function *(a::Rational{T}, b::AbsSeriesElem{Rational{T}}) where T <: Union{Int, BigInt}
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   set_prec!(z, precision(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   set_length!(z, normalise(z, len))
   return z
end

doc"""
    *(a::Integer, b::AbsSeriesElem)
> Return $a\times b$.
"""
function *(a::Integer, b::AbsSeriesElem) 
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   set_prec!(z, precision(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   set_length!(z, normalise(z, len))
   return z
end

doc"""
    *(a::fmpz, b::AbsSeriesElem)
> Return $a\times b$.
"""
function *(a::fmpz, b::AbsSeriesElem) 
   len = length(b)
   z = parent(b)()
   fit!(z, len)
   set_prec!(z, precision(b))
   for i = 1:len
      z = setcoeff!(z, i - 1, a*coeff(b, i - 1))
   end
   set_length!(z, normalise(z, len))
   return z
end

doc"""
    *{T <: RingElem}(a::AbsSeriesElem{T}, b::T)
> Return $a\times b$.
"""
*(a::AbsSeriesElem{T}, b::T) where {T <: RingElem} = b*a

doc"""
    *{T <: Union{Int, BigInt}}(a::AbsSeriesElem{Rational{T}}, b::Rational{T})
> Return $a\times b$.
"""
*(a::AbsSeriesElem{Rational{T}}, b::Rational{T}) where T <: Union{Int, BigInt} = b*a

doc"""
    *(a::AbsSeriesElem, b::Integer)
> Return $a\times b$.
"""
*(a::AbsSeriesElem, b::Integer) = b*a

doc"""
    *(a::AbsSeriesElem, b::fmpz)
> Return $a\times b$.
"""
*(a::AbsSeriesElem, b::fmpz) = b*a

doc"""
    +{T <: RingElem}(a::T, b::AbsSeriesElem{T})
> Return $a + b$.
"""
+(a::T, b::AbsSeriesElem{T}) where {T <: RingElem} = parent(b)(a) + b

doc"""
    +{T <: Union{Int, BigInt}}(a::Rational{T}, b::AbsSeriesElem{Rational{T}})
> Return $a + b$.
"""
+(a::Rational{T}, b::AbsSeriesElem{Rational{T}}) where T <: Union{Int, BigInt} = parent(b)(a) + b

doc"""
    +(a::Integer, b::AbsSeriesElem)
> Return $a + b$.
"""
+(a::Integer, b::AbsSeriesElem) = parent(b)(a) + b

doc"""
    +(a::fmpz, b::AbsSeriesElem)
> Return $a + b$.
"""
+(a::fmpz, b::AbsSeriesElem) = parent(b)(a) + b

doc"""
    +{T <: RingElem}(a::AbsSeriesElem{T}, b::T)
> Return $a + b$.
"""
+(a::AbsSeriesElem{T}, b::T) where {T <: RingElem} = b + a

doc"""
    +{T <: Union{Int, BigInt}}(a::AbsSeriesElem{Rational{T}}, b::Rational{T})
> Return $a + b$.
"""
+(a::AbsSeriesElem{Rational{T}}, b::Rational{T}) where T <: Union{Int, BigInt} = b + a

doc"""
    +(a::AbsSeriesElem, b::Integer)
> Return $a + b$.
"""
+(a::AbsSeriesElem, b::Integer) = b + a

doc"""
    +(a::AbsSeriesElem, b::fmpz)
> Return $a + b$.
"""
+(a::AbsSeriesElem, b::fmpz) = b + a

doc"""
    -{T <: RingElem}(a::T, b::AbsSeriesElem{T})
> Return $a - b$.
"""
-(a::T, b::AbsSeriesElem{T}) where {T <: RingElem} = parent(b)(a) - b

doc"""
    -{T <: Union{Int, BigInt}}(a::Rational{T}, b::AbsSeriesElem{Rational{T}})
> Return $a - b$.
"""
-(a::Rational{T}, b::AbsSeriesElem{Rational{T}}) where T <: Union{Int, BigInt} = parent(b)(a) - b

doc"""
    -(a::Integer, b::AbsSeriesElem)
> Return $a - b$.
"""
-(a::Integer, b::AbsSeriesElem) = parent(b)(a) - b

doc"""
    -(a::fmpz, b::AbsSeriesElem)
> Return $a - b$.
"""
-(a::fmpz, b::AbsSeriesElem) = parent(b)(a) - b

doc"""
    -{T <: RingElem}(a::AbsSeriesElem{T}, b::T)
> Return $a - b$.
"""
-(a::AbsSeriesElem{T}, b::T) where {T <: RingElem} = a - parent(a)(b)

doc"""
    -{T <: Union{Int, BigInt}}(a::AbsSeriesElem{Rational{T}}, b::Rational{T})
> Return $a - b$.
"""
-(a::AbsSeriesElem{Rational{T}}, b::Rational{T}) where T <: Union{Int, BigInt} = a - parent(a)(b)

doc"""
    -(a::AbsSeriesElem, b::Integer)
> Return $a - b$.
"""
-(a::AbsSeriesElem, b::Integer) = a - parent(a)(b)

doc"""
    -(a::AbsSeriesElem, b::fmpz)
> Return $a - b$.
"""
-(a::AbsSeriesElem, b::fmpz) = a - parent(a)(b)

###############################################################################
#
#   Shifting
#
###############################################################################

doc"""
    shift_left(x::AbsSeriesElem, n::Int)
> Return the power series $f$ shifted left by $n$ terms, i.e. multiplied by
> $x^n$.
"""
function shift_left(x::AbsSeriesElem{T}, len::Int) where {T <: RingElement}
   len < 0 && throw(DomainError())
   xlen = length(x)
   prec = precision(x) + len
   prec = min(prec, max_precision(parent(x)))
   if xlen == 0
      z = zero(parent(x))
      set_prec!(z, prec)
      return z
   end
   zlen = min(prec, xlen + len)
   z = parent(x)()
   fit!(z, zlen)
   set_prec!(z, prec)
   for i = 1:len
      z = setcoeff!(z, i - 1, zero(base_ring(x)))
   end
   for i = 1:xlen
      z = setcoeff!(z, i + len - 1, coeff(x, i - 1))
   end
   set_length!(z, normalise(z, zlen))
   return z
end

doc"""
    shift_right(f::AbsSeriesElem, n::Int)
> Return the power series $f$ shifted right by $n$ terms, i.e. divided by
> $x^n$.
"""
function shift_right(x::AbsSeriesElem{T}, len::Int) where {T <: RingElement}
   len < 0 && throw(DomainError())
   xlen = length(x)
   if len >= xlen
      z = zero(parent(x))
      set_prec!(z, max(0, precision(x) - len))
      return z
   end
   z = parent(x)()
   fit!(z, xlen - len)
   set_prec!(z, precision(x) - len)
   for i = 1:xlen - len
      z = setcoeff!(z, i - 1, coeff(x, i + len - 1))
   end
   return z
end

###############################################################################
#
#   Truncation
#
###############################################################################

doc"""
    truncate(a::AbsSeriesElem, n::Int)
> Return $a$ truncated to $n$ terms.
"""
function truncate(a::AbsSeriesElem{T}, prec::Int) where {T <: RingElement}
   prec < 0 && throw(DomainError())
   len = length(a)
   if precision(a) <= prec
      return a
   end
   z = parent(a)()
   fit!(z, prec)
   set_prec!(z, prec)
   for i = 1:min(prec, len)
      z = setcoeff!(z, i - 1, coeff(a, i - 1))
   end
   for i = len + 1:prec
      z = setcoeff!(z, i - 1, zero(base_ring(a)))
   end
   set_length!(z, normalise(z, prec))
   return z
end

###############################################################################
#
#   Powering
#
###############################################################################

doc"""
    ^{T <: RingElement}(a::AbsSeriesElem{T}, b::Int)
> Return $a^b$. We require $b \geq 0$.
"""
function ^(a::AbsSeriesElem{T}, b::Int) where {T <: RingElement}
   b < 0 && throw(DomainError())
   # special case powers of x for constructing power series efficiently
   if precision(a) > 0 && isgen(a) && b > 0
      return shift_left(a, b - 1)
   elseif length(a) == 1
      z = parent(a)(coeff(a, 0)^b)
      set_prec!(z, precision(a))
      return z
   elseif b == 0
      z = one(parent(a))
      set_prec!(z, precision(a))
      return z
   else
      bit = ~((~UInt(0)) >> 1)
      while (UInt(bit) & b) == 0
         bit >>= 1
      end
      z = a
      bit >>= 1
      while bit !=0
         z = z*z
         if (UInt(bit) & b) != 0
            z *= a
         end
         bit >>= 1
      end
      return z
   end
end

###############################################################################
#
#   Comparison
#
###############################################################################

doc"""
    =={T <: RingElement}(x::AbsSeriesElem{T}, y::AbsSeriesElem{T})
> Return `true` if $x == y$ arithmetically, otherwise return `false`. Recall
> that power series to different precisions may still be arithmetically
> equal to the minimum of the two precisions.
"""
function ==(x::AbsSeriesElem{T}, y::AbsSeriesElem{T}) where {T <: RingElement}
   check_parent(x, y)
   prec = min(precision(x), precision(y))
   m1 = min(length(x), length(y))
   m2 = max(length(x), length(y))
   m1 = min(m1, prec)
   m2 = min(m2, prec)
   if length(x) >= m2
      for i = m1 + 1: m2
         if !iszero(coeff(x, i - 1))
            return false
          end
      end
   else
      for i = m1 + 1: m2
         if !iszero(coeff(y, i - 1))
            return false
          end
      end
   end
   for i = 1:m1
      if coeff(x, i - 1) != coeff(y, i - 1)
         return false
      end
   end
   return true
end

doc"""
    isequal{T <: RingElement}(x::AbsSeriesElem{T}, y::AbsSeriesElem{T})
> Return `true` if $x == y$ exactly, otherwise return `false`. Only if the
> power series are precisely the same, to the same precision, are they declared
> equal by this function.
"""
function isequal(x::AbsSeriesElem{T}, y::AbsSeriesElem{T}) where {T <: RingElement}
   if parent(x) != parent(y)
      return false
   end
   if precision(x) != precision(y) || length(x) != length(y)
      return false
   end
   for i = 1:length(x)
      if !isequal(coeff(x, i - 1), coeff(y, i - 1))
         return false
      end
   end
   return true
end

###############################################################################
#
#   Ad hoc comparison
#
###############################################################################

doc"""
    =={T <: RingElem}(x::AbsSeriesElem{T}, y::T)
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::AbsSeriesElem{T}, y::T) where {T <: RingElem} = precision(x) == 0 ||
      ((length(x) == 0 && iszero(y)) || (length(x) == 1 && coeff(x, 0) == y))

doc"""
    =={T <: Union{Int, BigInt}}(x::AbsSeriesElem{Rational{T}}, y::Rational{T})
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::AbsSeriesElem{Rational{T}}, y::Rational{T}) where T <: Union{Int, BigInt} = precision(x) == 0 ||
      ((length(x) == 0 && iszero(y)) || (length(x) == 1 && coeff(x, 0) == y))

doc"""
    =={T <: RingElem}(x::T, y::AbsSeriesElem{T})
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::T, y::AbsSeriesElem{T}) where {T <: RingElem} = y == x

doc"""
    =={T <: Union{Int, BigInt}}(x::Rational{T}, y::AbsSeriesElem{Rational{T}})
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::Rational{T}, y::AbsSeriesElem{Rational{T}}) where T <: Union{Int, BigInt} = y == x

doc"""
    ==(x::AbsSeriesElem, y::Integer)
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::AbsSeriesElem, y::Integer) = precision(x) == 0 || ((length(x) == 0 && iszero(y))
                                       || (length(x) == 1 && coeff(x, 0) == y))

doc"""
    ==(x::AbsSeriesElem, y::fmpz)
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::AbsSeriesElem, y::fmpz) = precision(x) == 0 || ((length(x) == 0 && iszero(y))
                                       || (length(x) == 1 && coeff(x, 0) == y))

doc"""
    ==(x::Integer, y::AbsSeriesElem)
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::Integer, y::AbsSeriesElem) = y == x

doc"""
    ==(x::fmpz, y::AbsSeriesElem)
> Return `true` if $x == y$ arithmetically, otherwise return `false`.
"""
==(x::fmpz, y::AbsSeriesElem) = y == x

###############################################################################
#
#   Exact division
#
###############################################################################

doc"""
    divexact{T <: RingElement}(a::AbsSeriesElem{T}, b::AbsSeriesElem{T})
> Return $a/b$. Requires $b$ to be invertible.
"""
function divexact(x::AbsSeriesElem{T}, y::AbsSeriesElem{T}) where {T <: RingElement}
   check_parent(x, y)
   iszero(y) && throw(DivideError())
   v2 = valuation(y)
   if v2 != 0
      v1 = valuation(x)
      if v1 >= v2
         x = shift_right(x, v2)
         y = shift_right(y, v2)
      end
   end
   y = truncate(y, precision(x))
   return x*inv(y)
end

###############################################################################
#
#   Ad hoc exact division
#
###############################################################################

doc"""
    divexact{T <: RingElem}(a::AbsSeriesElem{T}, b::Integer)
> Return $a/b$ where the quotient is expected to be exact.
"""
function divexact(x::AbsSeriesElem{T}, y::Integer) where {T <: RingElem}
   y == 0 && throw(DivideError())
   lenx = length(x)
   z = parent(x)()
   fit!(z, lenx)
   set_prec!(z, precision(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(coeff(x, i - 1), y))
   end
   return z
end

doc"""
    divexact{T <: RingElem}(a::AbsSeriesElem{T}, b::fmpz)
> Return $a/b$ where the quotient is expected to be exact.
"""
function divexact(x::AbsSeriesElem{T}, y::fmpz) where {T <: RingElem}
   iszero(y) && throw(DivideError())
   lenx = length(x)
   z = parent(x)()
   fit!(z, lenx)
   set_prec!(z, precision(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(coeff(x, i - 1), y))
   end
   return z
end

doc"""
    divexact{T <: RingElem}(a::AbsSeriesElem{T}, b::T)
> Return $a/b$ where the quotient is expected to be exact.
"""
function divexact(x::AbsSeriesElem{T}, y::T) where {T <: RingElem}
   iszero(y) && throw(DivideError())
   lenx = length(x)
   z = parent(x)()
   fit!(z, lenx)
   set_prec!(z, precision(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(coeff(x, i - 1), y))
   end
   return z
end

doc"""
    divexact{T <: Union{Int, BigInt}}(a::AbsSeriesElem{Rational{T}}, b::Rational{T})
> Return $a/b$ where the quotient is expected to be exact.
"""
function divexact(x::AbsSeriesElem{Rational{T}}, y::Rational{T}) where T <: Union{Int, BigInt}
   iszero(y) && throw(DivideError())
   lenx = length(x)
   z = parent(x)()
   fit!(z, lenx)
   set_prec!(z, precision(x))
   for i = 1:lenx
      z = setcoeff!(z, i - 1, divexact(coeff(x, i - 1), y))
   end
   return z
end

###############################################################################
#
#   Inversion
#
###############################################################################

doc"""
   inv(a::AbsSeriesElem)
> Return the inverse of the power series $a$, i.e. $1/a$.
"""
function inv(a::AbsSeriesElem)
   iszero(a) && throw(DivideError())
   !isunit(a) && error("Unable to invert power series")
   a1 = coeff(a, 0)
   ainv = parent(a)()
   fit!(ainv, precision(a))
   set_prec!(ainv, precision(a))
   if precision(a) != 0
      ainv = setcoeff!(ainv, 0, divexact(one(base_ring(a)), a1))
   end
   a1 = -a1
   for n = 2:precision(a)
      s = coeff(a, 1)*coeff(ainv, n - 2)
      for i = 2:min(n, length(a)) - 1
         s += coeff(a, i)*coeff(ainv, n - i - 1)
      end
      ainv = setcoeff!(ainv, n - 1, divexact(s, a1))
   end
   set_length!(ainv, normalise(ainv, precision(a)))
   return ainv
end

###############################################################################
#
#   Special functions
#
###############################################################################

doc"""
    exp(a::AbsSeriesElem)
> Return the exponential of the power series $a$.
"""
function exp(a::AbsSeriesElem)
   if iszero(a)
      z = one(parent(a))
      set_prec!(z, precision(a))
      return z
   end
   z = parent(a)()
   fit!(z, precision(a))
   set_prec!(z, precision(a))
   z = setcoeff!(z, 0, exp(coeff(a, 0)))
   len = length(a)
   for k = 1 : precision(a) - 1
      s = zero(base_ring(a))
      for j = 1 : min(k + 1, len) - 1
         s += j * coeff(a, j) * coeff(z, k - j)
      end
      !isunit(base_ring(a)(k)) && error("Unable to divide in exp")
      z = setcoeff!(z, k, divexact(s, k))
   end
   set_length!(z, normalise(z, precision(a)))
   return z
end

###############################################################################
#
#   Unsafe functions
#
###############################################################################

function fit!(c::GenAbsSeries{T}, n::Int) where {T <: RingElement}
   if length(c.coeffs) < n
      t = c.coeffs
      c.coeffs = Array{T}(n)
      for i = 1:c.length
         c.coeffs[i] = t[i]
      end
      for i = length(c) + 1:n
         c.coeffs[i] = zero(base_ring(c))
      end
   end
   return nothing
end

function setcoeff!(c::GenAbsSeries{T}, n::Int, a::T) where {T <: RingElement}
   if (!iszero(a) && precision(c) > n) || n + 1 <= c.length
      fit!(c, n + 1)
      c.coeffs[n + 1] = a
      c.length = max(length(c), n + 1)
      # don't normalise
   end
   return c
end

function mul!(c::GenAbsSeries{T}, a::GenAbsSeries{T}, b::GenAbsSeries{T}) where {T <: RingElement}
   lena = length(a)
   lenb = length(b)

   aval = valuation(a)
   bval = valuation(b)

   prec = min(precision(a) + bval, precision(b) + aval)
   prec = min(prec, max_precision(parent(c)))

   lena = min(lena, prec)
   lenb = min(lenb, prec)

   if lena == 0 || lenb == 0
      c.length = 0
   else
      t = base_ring(a)()

      lenc = min(lena + lenb - 1, prec)
      fit!(c, lenc)

      for i = 1:min(lena, lenc)
         c.coeffs[i] = mul!(c.coeffs[i], coeff(a, i - 1), coeff(b, 0))
      end

      if lenc > lena
         for i = 2:min(lenb, lenc - lena + 1)
            c.coeffs[lena + i - 1] = mul!(c.coeffs[lena + i - 1], coeff(a, lena - 1), coeff(b, i - 1))
         end
      end

      for i = 1:lena - 1
         if lenc > i
            for j = 2:min(lenb, lenc - i + 1)
               t = mul!(t, coeff(a, i - 1), coeff(b, j - 1))
               c.coeffs[i + j - 1] = addeq!(c.coeffs[i + j - 1], t)
            end
         end
      end

      c.length = normalise(c, lenc)
   end
   c.prec = prec
   return c
end

function addeq!(c::GenAbsSeries{T}, a::GenAbsSeries{T}) where {T <: RingElement}
   lenc = length(c)
   lena = length(a)

   prec = min(precision(a), precision(c))

   lena = min(lena, prec)
   lenc = min(lenc, prec)

   len = max(lenc, lena)
   fit!(c, len)
   for i = 1:lena
      c.coeffs[i] = addeq!(c.coeffs[i], coeff(a, i - 1))
   end
   c.length = normalise(c, len)
   c.prec = prec
   return c
end

###############################################################################
#
#   Promotion rules
#
###############################################################################

function promote_rule(::Type{GenAbsSeries{T}}, ::Type{V}) where {T <: RingElement, V <: Integer}
   return GenAbsSeries{T}
end

function promote_rule(::Type{GenAbsSeries{T}}, ::Type{T}) where {T <: RingElement}
   return GenAbsSeries{T}
end

function promote_rule1(::Type{GenAbsSeries{T}}, ::Type{GenAbsSeries{U}}) where {T <: RingElement, U <: RingElement}
   promote_rule(T, GenAbsSeries{U}) == T ? GenAbsSeries{T} : Union{}
end

function promote_rule(::Type{GenAbsSeries{T}}, ::Type{U}) where {T <: RingElement, U <: RingElement}
   promote_rule(T, U) == T ? GenAbsSeries{T} : promote_rule1(U, GenAbsSeries{T})
end

###############################################################################
#
#   Parent object call overload
#
###############################################################################

function (a::GenAbsSeriesRing{T} where {T <: RingElement})(b::RingElement)
   return a(base_ring(a)(b))
end

function (a::GenAbsSeriesRing{T})() where {T <: RingElement}
   z = GenAbsSeries{T}(Array{T}(0), 0, a.prec_max)
   z.parent = a
   return z
end

function (a::GenAbsSeriesRing{T})(b::Integer) where {T <: RingElement}
   if b == 0
      z = GenAbsSeries{T}(Array{T}(0), 0, a.prec_max)
   else
      z = GenAbsSeries{T}([base_ring(a)(b)], 1, a.prec_max)
   end
   z.parent = a
   return z
end

function (a::GenAbsSeriesRing{T})(b::fmpz) where {T <: RingElement}
   if b == 0
      z = GenAbsSeries{T}(Array{T}(0), 0, a.prec_max)
   else
      z = GenAbsSeries{T}([base_ring(a)(b)], 1, a.prec_max)
   end
   z.parent = a
   return z
end

function (a::GenAbsSeriesRing{T})(b::T) where {T <: RingElement}
   parent(b) != base_ring(a) && error("Unable to coerce to power series")
   if b == 0
      z = GenAbsSeries{T}(Array{T}(0), 0, a.prec_max)
   else
      z = GenAbsSeries{T}([b], 1, a.prec_max)
   end
   z.parent = a
   return z
end

function (a::GenAbsSeriesRing{T})(b::AbsSeriesElem{T}) where {T <: RingElement}
   parent(b) != a && error("Unable to coerce power series")
   return b
end

function (a::GenAbsSeriesRing{T})(b::Array{T, 1}, len::Int, prec::Int) where {T <: RingElement}
   if length(b) > 0
      parent(b[1]) != base_ring(a) && error("Unable to coerce to power series")
   end
   z = GenAbsSeries{T}(b, len, prec)
   z.parent = a
   return z
end

###############################################################################
#
#   PowerSeriesRing constructor
#
###############################################################################

# see RelSeries.jl
