module IndexingTools

export
    @range,
    @reverse_range

using Base: OneTo

"""
    IndexingTools.ContiguousRange

is an alias for `AbstractUnitRange{Int}`, the type of ranges in an
[`IndexingTools.CartesianBox`][(@ref).

"""
const ContiguousRange = AbstractUnitRange{Int}

"""
    IndexingTools.CartesianBox{N}

is an alias for `CartesianIndices{N}` but restricted to have contiguous
Cartesian indices.  Since Julia 1.6, `CartesianIndices` may have non-unit step,
hence non-contiguous indices.

"""
const CartesianBox{N} = CartesianIndices{N,<:NTuple{N,ContiguousRange}}

"""
    IndexingTools.StretchBy(δ) -> obj

yields a callable object `obj` such that `obj(x)` yields `x` stretched by
offset `δ`.

""" StretchBy

"""
    IndexingTools.ShrinkBy(δ) -> obj

yields a callable object `obj` such that `obj(x)` yields `x` shrinked by offset
`δ`.

""" ShrinkBy

"""
    @range expr

rewrites range expression `expr` with extended syntax.  The result is an
`Int`-valued index range (possibly Cartesian) where indices are running in the
forward direction (with a positive step).

"""
macro range(ex::Expr)
    esc(Expr(:call, :(IndexingTools.forward), rewrite!(ex)))
end

"""
    @reverse_range expr

rewrites range expression `expr` with extended syntax.  The result is an
`Int`-valued index range (possibly Cartesian) where indices are running in the
reverse direction (with a negative step).

"""
macro reverse_range(ex::Expr)
    esc(Expr(:call, :(IndexingTools.backward), rewrite!(ex)))
end

rewrite!(x) = x # left anything else untouched

function rewrite!(ex::Expr)
    if ex.head === :call
        if ex.args[1] === :(+)
            ex.args[1] = :(IndexingTools.plus)
        elseif ex.args[1] === :(-)
            ex.args[1] = :(IndexingTools.minus)
        elseif ex.args[1] === :(∩)
            ex.args[1] = :(IndexingTools.cap)
        elseif ex.args[1] === :(±)
            ex.args[1] = :(IndexingTools.stretch)
        elseif ex.args[1] === :(∓)
            ex.args[1] = :(IndexingTools.shrink)
        end
        for i in 2:length(ex.args)
            rewrite!(ex.args[i])
        end
    end
    return ex
end

"""
    IndexingTools.forward(R)

yields an object which contains the same (Cartesian) indices as `R` but with
positive step(s) and `Int`-valued.

"""
forward(a::AbstractUnitRange{Int}) = a
forward(a::AbstractUnitRange{<:Integer}) = to_int(a)
function forward(a::OrdinalRange{<:Integer,<:Integer})
    first_a, step_a, last_a = first_step_last(a)
    return step_a ≥ 0 ? (first_a:step_a:last_a) : (last_a:-step_a:first_a)
end
forward(a::CartesianIndices) =
    isa(a, CartesianBox) ? a : CartesianIndices(map(forward, ranges(a)))

"""
    IndexingTools.backward(R)

yields an object which constains the same (Cartesian) indices as `R`
but with negative step(s) and `Int`-valued.

"""
function backward(a::AbstractUnitRange{<:Integer})
    first_a, last_a = first_last(a)
    return last_a:-1:first_a
end
function backward(a::OrdinalRange{<:Integer,<:Integer})
    first_a, step_a, last_a = first_step_last(a)
    return step_a ≤ 0 ? (first_a:step_a:last_a) : (last_a:-step_a:first_a)
end
backward(a::CartesianIndices) = CartesianIndices(map(backward, ranges(a)))

"""
    IndexingTools.plus(a...)

yields the result of expression `+a`, `a + b`, `a + b + c...` in
[`@range`](@ref) macro.

""" plus

# Use ordinary + by default and deal with multiple arguments.
plus(a) = +a
plus(a, b) = a + b
@inline plus(a, b, c...) = plus(plus(a, b), c...)

# Unary plus just converts to `Int`-valued object.
plus(a::Int) = a
plus(a::Integer) = to_int(a)
plus(a::AbstractUnitRange{Int}) = a
plus(a::AbstractUnitRange{Integer}) = to_int(a)
plus(a::OrdinalRange{<:Integer,<:Integer}) = forward(a)
plus(a::CartesianIndex) = a
plus(a::CartesianIndices) = forward(a)

# Binary plus.
plus(a::Integer, b::Integer) = to_int(a) + to_int(b)
function plus(a::AbstractUnitRange{<:Integer}, b::Integer)
    first_a, last_a = first_last(a)
    int_b = to_int(b)
    return (first_a + int_b):(last_a + int_b)
end
plus(a::Integer, b::AbstractUnitRange{<:Integer}) = plus(b, a)
function plus(a::OrdinalRange{<:Integer,<:Integer}, b::Integer)
    first_a, step_a, last_a = first_step_last(a)
    int_b = to_int(b)
    if step_a ≥ 0
        return (first_a + int_b):(step_a):(last_a + int_b)
    else
        return (last_a + int_b):(-step_a):(first_a + int_b)
    end
end
plus(a::Integer, b::OrdinalRange{<:Integer,<:Integer}) = plus(b, a)

"""
    IndexingTools.minus(a...)

yields the result of expression `-a` and `a - b` in [`@range`](@ref) macro.

""" minus

# Use ordinary - by default.
minus(a) = -a
minus(a, b) = a - b

# Unary minus yields positive step sign.
minus(a::Integer) = -to_int(a)
function minus(a::AbstractUnitRange{<:Integer})
    first_a, last_a = first_last(a)
    return (-last_a):(-first_a)
end
function minus(a::OrdinalRange{<:Integer,<:Integer})
    first_a, step_a, last_a = first_step_last(a)
    if step_a ≥ 0
        return (-last_a):(step_a):(-first_a)
    else
        return (-first_a):(-step_a):(-last_a)
    end
end
minus(a::CartesianIndex) = -a
minus(a::CartesianIndices) = CartesianIndices(map(minus, ranges(a)))

# Binary minus.
minus(a::Integer, b::Integer) = to_int(a) - to_int(b)
function minus(a::AbstractUnitRange{<:Integer}, b::Integer)
    first_a, last_a = first_last(a)
    int_b = to_int(b)
    return (first_a - int_b):(last_a - int_b)
end
function minus(a::Integer, b::AbstractUnitRange{<:Integer})
    int_a = to_int(a)
    first_b, last_b = first_last(b)
    return (int_a - last_b):(int_a - first_b)
end
function minus(a::OrdinalRange{<:Integer,<:Integer}, b::Integer)
    first_a, step_a, last_a = first_step_last(a)
    int_b = to_int(b)
    if step_a ≥ 0
        return (first_a - int_b):(step_a):(last_a - int_b)
    else
        return (last_a - int_b):(-step_a):(first_a - int_b)
    end
end
function minus(a::Integer, b::OrdinalRange{<:Integer,<:Integer})
    int_a = to_int(a)
    first_b, step_b, last_b = first_step_last(b)
    if step_b ≥ 0
        return (int_a - last_b):(step_b):(int_a - first_b)
    else
        return (int_a - first_b):(-step_b):(int_a - last_b)
    end
end

"""
    IndexingTools.cap(a...)

yields the result of expression `a ∩ b` in [`@range`](@ref) macro.

"""
cap(a::Integer, b::AbstractUnitRange{<:Integer}) = cap(b, a)
function cap(a::AbstractUnitRange{<:Integer}, b::Integer)
    first_a, last_a = first_last(a)
    int_b = to_int(b)
    ifelse((first_a ≤ int_b)&(int_b ≤ last_a), int_b:int_b, 1:0)
end
cap(a::OneTo, b::OneTo) = OneTo{Int}(min(to_int(a.stop), to_int(b.stop)))
function cap(a::AbstractUnitRange{<:Integer},
             b::AbstractUnitRange{<:Integer})
    first_a, last_a = first_last(a)
    first_b, last_b = first_last(b)
    return max(first_a, first_b):min(last_a, last_b)
end
function cap(a::OrdinalRange{<:Integer,<:Integer},
             b::OrdinalRange{<:Integer,<:Integer})
    return forward(a) ∩ forward(b) # FIXME: Optimize?
end

# Combine CartesianIndices and CartesianIndices or CartesianIndex.
for f in (:plus, :minus, :cap)
    @eval begin
        $f(a::CartesianIndices{N}, b::CartesianIndex{N}) where {N} =
            CartesianIndices(map($f, ranges(a), Tuple(b)))
        $f(a::CartesianIndex{N}, b::CartesianIndices{N}) where {N} =
            CartesianIndices(map($f, Tuple(a), ranges(b)))
    end
end

cap(a::CartesianIndices{N}, b::CartesianIndices{N}) where {N} =
    CartesianIndices(map(cap, ranges(a), ranges(b)))

"""
    IndexingTools.stretch(a, b)

yields the result of stretching `a` by amount `b`.  This is equivalent to the
expression `a ± b` in [`@range`](@ref) macro.

"""
stretch(a::Int, b::Int) = (a - b):(a + b)
function stretch(a::AbstractUnitRange{<:Integer}, b::Integer)
    first_a, last_a = first_last(a)
    int_b = to_int(b)
    return (first_a - int_b):(last_a + int_b)
end
function stretch(a::OrdinalRange{<:Integer}, b::Integer)
    first_a, step_a, last_a = first_step_last(a)
    int_b = to_int(b)
    (int_b % step_a) == 0 || throw(ArgumentError("stretch must be multiple of the step"))
    if step_a ≥ 0
        return (first_a - int_b):step_a:(last_a + int_b)
    else
        return (last_a - int_b):(-step_a):(first_a + int_b)
    end
end

"""
    IndexingTools.shrink(a, b)

yields the result of shrinking `a` by amount `b`.  This is equivalent to the
expression `a ∓ b` in [`@range`](@ref) macro.

"""
shrink(a::Int, b::Int) = (a + b):(a - b)
function shrink(a::AbstractUnitRange{<:Integer}, b::Integer)
    first_a, last_a = first_last(a)
    int_b = to_int(b)
    return (first_a + int_b):(last_a - int_b)
end
function shrink(a::OrdinalRange{<:Integer}, b::Integer)
    first_a, step_a, last_a = first_step_last(a)
    int_b = to_int(b)
    (int_b % step_a) == 0 || throw(ArgumentError("shrink must be multiple of the step"))
    if step_a ≥ 0
        return (first_a + int_b):step_a:(last_a - int_b)
    else
        return (last_a + int_b):(-step_a):(first_a - int_b)
    end
end

for (f, s) in ((:stretch, :StretchBy),
               (:shrink, :ShrinkBy))
    @eval begin
        struct $s <: Function
            δ::Int # left operand
        end
        (obj::$s)(x::Integer) = $f(x, obj.δ)
        (obj::$s)(x::OrdinalRange{<:Integer,<:Integer}) = $f(x, obj.δ)

        $f(a::Integer, b::Integer) = $f(to_int(a), to_int(b))

        $f(a::CartesianIndices{N}, b::CartesianIndex{N}) where {N} =
            CartesianIndices(map($f, ranges(a), Tuple(b)))
        $f(a::CartesianIndices{N}, b::NTuple{N,Integer}) where {N} =
            CartesianIndices(map($f, ranges(a), b))
        $f(a::CartesianIndices, b::Integer) =
            CartesianIndices(map($s(b), ranges(a)))
    end
    # A Cartesian index can be stretched, not shrinked.
    if f === :stretch
        @eval begin
            $f(a::CartesianIndex{N}, b::CartesianIndex{N}) where {N} =
                CartesianIndices(map($f, Tuple(a), Tuple(b)))
            $f(a::CartesianIndex{N}, b::NTuple{N,Integer}) where {N} =
                CartesianIndices(map($f, Tuple(a), b))
            $f(a::CartesianIndex, b::Integer) =
            CartesianIndices(map($s(b), Tuple(a)))
        end
    end
end

"""
    IndexingTools.ranges(R)

yields the list of ranges in Cartesian indices `R`.

"""
ranges(R::CartesianIndices) = getfield(R, :indices)

"""
    IndexingTools.first_last(x) -> (first_x, last_x)

yields the 2-tuple `(first(x), last(x))` converted to be `Int`-valued.

"""
first_last(x::AbstractUnitRange{<:Integer}) =
    (to_int(first(x)), to_int(last(x)))

"""
    IndexingTools.first_step_last(x) -> (first_x, step_x, last_x)

yields the 3-tuple `(first(x), step(x), last(x))` converted to be `Int`-valued.

"""
first_step_last(x::AbstractUnitRange{<:Integer}) =
    (to_int(first(x)), 1, to_int(last(x)))

first_step_last(x::OrdinalRange{<:Integer,<:Integer}) =
    (to_int(first(x)), to_int(step(x)), to_int(last(x)))

"""
    IndexingTools.to_int(x)

yields an `Int`-valued equivalent of `x`.

"""
to_int(x::Int) = x
to_int(x::Integer) = to_type(Int, x)

to_int(x::OneTo{Int}) = x
to_int(x::OneTo) = OneTo{Int}(x.stop)

to_int(x::AbstractUnitRange{Int}) = x
to_int(x::AbstractUnitRange{<:Integer}) = to_int(first(x)):to_int(last(x))

to_int(x::OrdinalRange{Int,Int}) = x
to_int(x::OrdinalRange{<:Integer}) =
    to_int(first(x)):to_int(step(x)):to_int(last(x))

# Cartesian indices are already `Int`-valued.
to_int(x::CartesianIndex) = x
to_int(x::CartesianIndices) = x

to_int(x::Tuple{Vararg{Int}}) = x
to_int(x::Tuple{Vararg{Integer}}) = map(to_int, x)

"""
    IndexingTools.to_type(T, x)

yields `x` surely converted to type `T`.

"""
to_type(::Type{T}, x::T) where {T} = x
to_type(::Type{T}, x) where {T} = convert(T, x)::T

end
