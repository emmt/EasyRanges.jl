module EasyRanges

export
    @range,
    @reverse_range

using Base: OneTo

"""
    @range expr

rewrites range expression `expr` with extended syntax. The result is an `Int`-valued index
range (possibly Cartesian) where indices are running in the forward direction (with a
positive step). Call [`@reverse_range`](@ref) if a negative step is required.

Operations (`+`, `-`, `∩`, etc.) in `expr` shall only involve indices or index ranges. The
syntax `\$(subexpr)` may be used to protect any sub-expression `subexpr` of `expr` from
being interpreted as a range expression.

See [`EasyRanges.normalize`](@ref) to implement non-standard index or range types in the
`@range` and [`@reverse_range`](@ref) macros.

"""
macro range(ex::Expr)
    esc(Expr(:call, :(EasyRanges.forward), rewrite!(ex)))
end

"""
    @reverse_range expr

rewrites range expression `expr` with extended syntax. The result is an `Int`-valued index
range (possibly Cartesian) where indices are running in the reverse direction (with a
negative step). Call [`@range`](@ref) if a positive step is required and see the
documentation of this macro for more explanations.

See [`EasyRanges.normalize`](@ref) to implement non-standard index or range types in the
[`@range`](@ref) and `@reverse_range` macros.

"""
macro reverse_range(ex::Expr)
    esc(Expr(:call, :(EasyRanges.backward), rewrite!(ex)))
end

rewrite!(x) = x # left anything else untouched

function rewrite!(ex::Expr)
    if ex.head === :call
        if ex.args[1] === :(+)
            ex.args[1] = :(EasyRanges.plus)
        elseif ex.args[1] === :(-)
            ex.args[1] = :(EasyRanges.minus)
        elseif ex.args[1] === :(∩) || ex.args[1] === :(intersect) || ex.args[1] == :(Base.intersect)
            ex.args[1] = :(EasyRanges.cap)
        elseif ex.args[1] === :(±)
            ex.args[1] = :(EasyRanges.stretch)
        elseif ex.args[1] === :(∓)
            ex.args[1] = :(EasyRanges.shrink)
        end
        for i in 2:length(ex.args)
            rewrite!(ex.args[i])
        end
    elseif ex.head === :($) && length(ex.args) == 1
        # Replace `$(expr)` by `identity(expr)`.
        ex.head = :call
        push!(ex.args, :(Base.identity), pop!(ex.args))
    end
    return ex
end

"""
    EasyRanges.normalize(x)

yields an object which represents the same (Cartesian) index or set of indices as `x` but
in one of the following forms:

- an integer `i::Int` if `x` is equivalent to a single linear index;

- a range of integers `r::AbstractRange{Int}` if `x` is equivalent to a range of linear
  indices;

- a multi-dimensional Cartesian index `I::CartesianIndex{N}` if `x` is equivalent to a
  single `N`-dimensional Cartesian index;

- a multi-dimensional Cartesian range `R::CartesianIndices{N}` if `x` is equivalent to a
  rectangular region of `N`-dimensional Cartesian indices.

This method may be extended by foreign packages to let `EasyRanges` known how to deal with
other types of indices or of set of indices provided they are equivalent to one of the
above canonical forms.

"""
normalize(x::Int) = x
normalize(x::Integer) = Int(x)
normalize(x::Tuple{Vararg{Int}}) = x
normalize(x::Tuple{Vararg{Integer}}) = map(normalize, x)
normalize(x::Base.OneTo{Int}) = x
normalize(x::Base.OneTo{<:Integer}) = Base.OneTo{Int}(x)
normalize(x::AbstractUnitRange{Int}) = x
normalize(x::AbstractUnitRange{<:Integer}) = AbstractUnitRange{Int}(x)
normalize(x::AbstractRange{Int}) = x
normalize(x::AbstractRange{<:Integer}) = _first(x) : _step(x) : _last(x)
normalize(x::CartesianIndex) = x
normalize(x::CartesianIndices) = x
@noinline normalize() = error("missing argument in `normalize(x)`")
@noinline normalize(@nospecialize(x)) =
    error("Unexpected object of type `$(typeof(x))` in argument of `@range` or `@reverse_range`. Possible solutions: (i) fix the range expression, (ii) use `\$(expr)` to prevent sub-expression `expr` from being interpreted as a range expression, or (iii) specialize `EasyRanges.normalize` for type `$(typeof(x))`")

"""
    EasyRanges.forward(x)

yields an object which represents the same index or set of indices as `x` but with
positive step(s) and `Int`-valued indices. Call [`EasyRanges.backward(x)](@ref
`EasyRanges.backward) to ensure negative step(s).

"""
forward(x) = _forward(normalize(x))

_forward(i::Int) = i
_forward(I::CartesianIndex) = I
_forward(r::AbstractUnitRange{Int}) = r
_forward(r::AbstractRange{Int}) = begin
    a = _first(r)
    b = _last(r)
    s = _step(r)
    return s ≥ zero(s) ? (a : s : b) : (b : -s : a)
end
_forward(R::CartesianIndices{N,<:NTuple{N,AbstractUnitRange{Int}}}) where {N} = R
_forward(R::CartesianIndices) = CartesianIndices(map(forward, ranges(R)))

"""
    EasyRanges.backward(x)

yields an object which represents the same index or set of indices as `x` but with
negative step(s) and `Int`-valued indices. Call [`EasyRanges.forward(x)](@ref
`EasyRanges.forward) to ensure positive step(s).

"""
backward(x) = _backward(normalize(x))

_backward(i::Int) = i
_backward(I::CartesianIndex) = I
_backward(r::AbstractUnitRange{Int}) = _last(r) : -1 : _first(r)
_backward(r::AbstractRange{Int}) = begin
    a = _first(r)
    b = _last(r)
    s = _step(r)
    return s ≤ zero(s) ? (a : s : b) : (b : -s : a)
end
_backward(R::CartesianIndices) = CartesianIndices(map(backward, ranges(R)))

"""
    EasyRanges.plus(x)
    EasyRanges.plus(x, y)
    EasyRanges.plus(x, y, z)

yield the result of expressions `+x`, `x + y`, or `x + y + z...` in [`@range`](@ref)
macro.

""" plus

# Unary plus just call `normalize`.
plus(x) = normalize(x)

# Addition of 2 arguments.
plus(x, y) = _plus(normalize(x), normalize(y))

_plus(x::Int, y::Int) = x + y
_plus(i::Int, r::AbstractRange{Int}) = _plus(r, i)
_plus(r::AbstractUnitRange{Int}, i::Int) = _first(r) + i : _last(r) + i
_plus(r::AbstractRange{Int}, i::Int) = _first(r) + i : _step(r) : _last(r) + i

# Addition of 3 or more arguments.
@inline plus(x, y, z...) = plus(plus(x, y), z...) # FIXME: _plus(normalize(x), plus(y, z...))

"""
    EasyRanges.minus(x)
    EasyRanges.minus(x, y)

yield the result of expressions `-x` or `x - y` in [`@range`](@ref) macro.

""" minus

# Unary minus.
minus(x) = _minus(normalize(x))

_minus(i::Int) = -i
_minus(r::AbstractUnitRange{Int}) = -_last(r) : -_first(r)
_minus(r::AbstractRange{Int}) = -_first(r) : -_step(r) : -_last(r)
_minus(I::CartesianIndex) = -I
_minus(R::CartesianIndices) = CartesianIndices(map(_minus, ranges(R)))

# Subtraction.
minus(x, y) = _minus(normalize(x), normalize(y))

_minus(x::Int, y::Int) = x - y
_minus(r::AbstractUnitRange{Int}, i::Int) = _first(r) - i : _last(r) - i
_minus(i::Int, r::AbstractUnitRange{Int}) = i - _last(r) : i - _first(r)
_minus(r::AbstractRange{Int}, i::Int) = _first(r) - i : _step(r) : _last(r) - i
_minus(i::Int, r::AbstractRange{Int}) = i - _first(r) : -_step(r) : i - _last(r)

"""
    EasyRanges.cap(a, b)

yields the result of expression `a ∩ b` in [`@range`](@ref) macro.

"""
cap(a, b) = _cap(normalize(a), normalize(b))

_cap(a::Int, b::Int) = ifelse(a == b, a:a, 1:0)
_cap(i::Int, r::AbstractRange{Int}) = _cap(r, i)
_cap(r::AbstractUnitRange{Int}, i::Int) = ifelse((_first(r) ≤ i)&(i ≤ _last(r)), i:i, 1:0)
_cap(r::AbstractRange{Int}, i::Int) = ifelse(i ∈ r, i:i, 1:0)
_cap(a::OneTo{Int}, b::OneTo{Int}) = OneTo{Int}(min(a.stop, b.stop))
_cap(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int}) =
    max(_first(a), _first(b)) : min(_last(a), _last(b))
_cap(a::AbstractRange{Int}, b::AbstractRange{Int}) =
    _forward(a) ∩ _forward(b) # FIXME: Optimize?
_cap(a::CartesianIndex{N}, b::CartesianIndex{N}) where {N} =
    CartesianIndices(map(_cap, Tuple(a), Tuple(b)))
_cap(a::CartesianIndices{N}, b::CartesianIndices{N}) where {N} =
    CartesianIndices(map(_cap, ranges(a), ranges(b)))

# Combine CartesianIndices and a CartesianIndex.
for f in (:_plus, :_minus, :_cap)
    @eval begin
        $f(a::CartesianIndices{N}, b::CartesianIndex{N}) where {N} =
            CartesianIndices(map($f, ranges(a), Tuple(b)))
        $f(a::CartesianIndex{N}, b::CartesianIndices{N}) where {N} =
            CartesianIndices(map($f, Tuple(a), ranges(b)))
    end
end

"""
    EasyRanges.stretch(a, b)

yields the result of stretching `a` by amount `b`. This is equivalent to the expression `a
± b` in [`@range`](@ref) macro.

"""
stretch(a, b) = _stretch(normalize(a), normalize(b))

_stretch(a::Int, b::Int) = a - b : a + b
_stretch(r::AbstractUnitRange{Int}, i::Int) = _first(r) - i : _last(r) + i
_stretch(r::AbstractRange{Int}, i::Int) = begin
    s = _step(r)
    iszero(i % s) || throw(ArgumentError("stretch must be multiple of the step"))
    return _first(r) - i : s : _last(r) + i
end

"""
    EasyRanges.shrink(a, b)

yields the result of shrinking `a` by amount `b`. This is equivalent to the expression `a
∓ b` in [`@range`](@ref) macro.

"""
shrink(a, b) = _shrink(normalize(a), normalize(b))

_shrink(a::Int, b::Int) = a + b : a - b
_shrink(r::AbstractUnitRange{Int}, i::Int) = _first(r) + i : _last(r) - i
_shrink(r::AbstractRange{Int}, i::Int) = begin
    s = _step(r)
    iszero(i % s) || throw(ArgumentError("shrink must be multiple of the step"))
    return _first(r) + i : s : _last(r) - i
end

for f in (:_stretch, :_shrink)
    @eval begin
        $f(R::CartesianIndices{N}, I::CartesianIndex{N}) where {N} =
            CartesianIndices(map($f, ranges(R), Tuple(I)))
        $f(R::CartesianIndices{N}, I::NTuple{N,Int}) where {N} =
            CartesianIndices(map($f, ranges(R), I))
        $f(R::CartesianIndices, i::Int) =
            CartesianIndices(map(Base.Fix2($f, i), ranges(R)))
    end
    # A Cartesian index can be stretched, not shrinked.
    if f === :_stretch
        @eval begin
            $f(a::CartesianIndex{N}, b::CartesianIndex{N}) where {N} =
                CartesianIndices(map($f, Tuple(a), Tuple(b)))
            $f(a::CartesianIndex{N}, b::NTuple{N,Integer}) where {N} =
                CartesianIndices(map($f, Tuple(a), b))
            $f(I::CartesianIndex, i::Int) =
                CartesianIndices(map(Base.Fix2($f, i), Tuple(I)))
        end
    end
end

# These versions ensure that and `Int` is returned.
_first(r::AbstractRange{<:Integer}) = normalize(first(r))
_last(r::AbstractRange{<:Integer}) = normalize(last(r))
_step(r::AbstractRange{<:Integer}) = normalize(step(r))

"""
    EasyRanges.ranges(R)

yields the list of ranges in Cartesian indices `R`.

"""
ranges(R::CartesianIndices) = getfield(R, :indices)

end
