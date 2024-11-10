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
negative step). Call [`@range`](@ref) if a positive step is required.

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
normalize(x::AbstractRange{<:Integer}) =
    normalize(first(x)) : normalize(step(x)) : normalize(last(x))
normalize(x::CartesianIndex) = x
normalize(x::CartesianIndices) = x
@noinline normalize() = error("missing argument in `normalize(x)`")
@noinline normalize(@nospecialize(x)) =
    error("unexpected object of type `$(typeof(x))` in `@range` expression, you may specialize `EasyRanges.normalize` for that type")

"""
    EasyRanges.forward(R)

yields an object which contains the same (Cartesian) indices as `R` but with positive
step(s) and `Int`-valued. Arguments of other types are returned unchanged.

"""
forward(x) = _forward(normalize(x))

_forward(i::Int) = i
_forward(I::CartesianIndex) = I
_forward(r::AbstractUnitRange{Int}) = r
_forward(r::OrdinalRange{Int,Int}) = begin
    first_r, step_r, last_r = first_step_last(r)
    return step_r ≥ zero(step_r) ?
        (first_r : step_r : last_r) :
        (last_r : -step_r : first_r)
end
_forward(R::CartesianIndices{N,<:NTuple{N,AbstractUnitRange{Int}}}) where {N} = R
_forward(R::CartesianIndices) = CartesianIndices(map(forward, ranges(R)))

"""
    EasyRanges.backward(R)

yields an object which constains the same (Cartesian) indices as `R` but with negative
step(s) and `Int`-valued. Arguments of other types are returned unchanged.

"""
backward(x) = _backward(normalize(x))

_backward(i::Int) = i
_backward(I::CartesianIndex) = I
_backward(r::AbstractUnitRange{Int}) = last(r) : -1 : first(r)
_backward(r::OrdinalRange{Int,Int}) = begin
    first_r, step_r, last_r = first_step_last(r)
    return step_r ≤ zero(step_r) ?
        (first_r : step_r : last_r) :
        (last_r : -step_r : first_r)
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
_plus(r::AbstractUnitRange{Int}, i::Int) = first(r) + i : last(r) + i
_plus(r::OrdinalRange{Int}, i::Int) = first(r) + i : step(r) : last(r) + i

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
_minus(r::AbstractUnitRange{Int}) = -last(r) : -first(r)
_minus(r::OrdinalRange{Int,Int}) = -first(r) : -step(r) : -last(r)
_minus(I::CartesianIndex) = -I
_minus(R::CartesianIndices) = CartesianIndices(map(_minus, ranges(R)))

# Subtraction.
minus(x, y) = _minus(normalize(x), normalize(y))

_minus(x::Int, y::Int) = x - y
_minus(r::AbstractUnitRange{Int}, i::Int) = first(r) - i : last(r) - i
_minus(i::Int, r::AbstractUnitRange{Int}) = i - last(r) : i - first(r)
_minus(r::OrdinalRange{Int,Int}, i::Int) = first(r) - i : step(r) : last(r) - i
_minus(i::Int, r::OrdinalRange{Int,Int}) = i - first(r) : -step(r) : i - last(r)

"""
    EasyRanges.cap(a, b)

yields the result of expression `a ∩ b` in [`@range`](@ref) macro.

"""
cap(a, b) = _cap(normalize(a), normalize(b))

_cap(a::Int, b::Int) = ifelse(a == b, a:a, 1:0)
_cap(i::Int, r::AbstractRange{Int}) = _cap(r, i)
_cap(r::AbstractUnitRange{Int}, i::Int) = ifelse((first(r) ≤ i)&(i ≤ last(r)), i:i, 1:0)
_cap(r::AbstractRange{Int}, i::Int) = ifelse(i ∈ r, i:i, 1:0)
_cap(a::OneTo{Int}, b::OneTo{Int}) = OneTo{Int}(min(a.stop, b.stop))
_cap(a::AbstractUnitRange{Int}, b::AbstractUnitRange{Int}) =
    max(first(a), first(b)) : min(last(a), last(b))
_cap(a::OrdinalRange{Int,Int}, b::OrdinalRange{Int,Int}) =
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
_stretch(r::AbstractUnitRange{Int}, i::Int) = first(r) - i : last(r) + i
_stretch(r::OrdinalRange{Int,Int}, i::Int) = begin
    s = step(r)
    iszero(i % s) || throw(ArgumentError("stretch must be multiple of the step"))
    return first(r) - i : s : last(r) + i
end

"""
    EasyRanges.shrink(a, b)

yields the result of shrinking `a` by amount `b`. This is equivalent to the expression `a
∓ b` in [`@range`](@ref) macro.

"""
shrink(a, b) = _shrink(normalize(a), normalize(b))

_shrink(a::Int, b::Int) = a + b : a - b
_shrink(r::AbstractUnitRange{Int}, i::Int) = first(r) + i : last(r) - i
_shrink(r::OrdinalRange{Int,Int}, i::Int) = begin
    s = step(r)
    iszero(i % s) || throw(ArgumentError("shrink must be multiple of the step"))
    return first(r) + i : s : last(r) - i
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

"""
    EasyRanges.ranges(R)

yields the list of ranges in Cartesian indices `R`.

"""
ranges(R::CartesianIndices) = getfield(R, :indices)

"""
    EasyRanges.first_last(x) -> (first_x, last_x)

yields the 2-tuple `(first(x), last(x))` converted to be `Int`-valued.

"""
first_last(x::AbstractUnitRange{<:Integer}) =
    (normalize(first(x)), normalize(last(x)))

first_last(x::CartesianIndices) = begin
    flag = true
    for r in ranges(x)
        flag &= (step(r) == 1)
    end
    flag || throw(ArgumentError("Cartesian ranges have non-unit step"))
    return (CartesianIndex(map(first, ranges(x))),
            CartesianIndex(map(last, ranges(x))))
end

"""
    EasyRanges.first_step_last(x) -> (first_x, step_x, last_x)

yields the 3-tuple `(first(x), step(x), last(x))` converted to be `Int`-valued.

"""
first_step_last(x::AbstractUnitRange{<:Integer}) =
    (normalize(first(x)), 1, normalize(last(x)))

first_step_last(x::OrdinalRange{<:Integer,<:Integer}) =
    (normalize(first(x)), normalize(step(x)), normalize(last(x)))

first_step_last(x::CartesianIndices) =
    (CartesianIndex(map(first, ranges(x))),
     CartesianIndex(map(step, ranges(x))),
     CartesianIndex(map(last, ranges(x))))

end
