# IndexingTools

[![Build Status](https://github.com/emmt/IndexingTools.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/emmt/IndexingTools.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Build Status](https://ci.appveyor.com/api/projects/status/github/emmt/IndexingTools.jl?svg=true)](https://ci.appveyor.com/project/emmt/IndexingTools-jl)
[![Coverage](https://codecov.io/gh/emmt/IndexingTools.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/emmt/IndexingTools.jl)

`IndexingTools` is a small Julia package dedicated at making life easier with,
possibly Cartesian, indices and ranges.  This package exports macros `@range`
and `@reverse_range` which take a single expression and rewrites it with
extended syntax rules to produce an `Int`-valued *index range* which may be a
step range or an instance of `CartesianIndices`.  These two macros differ in
the step sign of the result.


## Usage

```julia
using IndexingTools
```

exports two macros `@range` and `@reverse_range` used as:

```julia
@range expr
@reverse_range expr
```

to evaluate expression `expr` with special rules (see below) where integers,
Cartesian indices, and ranges of integers or of Cartesian indices are threated
specifically:

- integers are converted to `Int`, ranges to `Int`-valued ranges, and tuples of
  integers to tuples of `Int`;

- arithmetic expressions only involving indices and ranges yield lightweight
  and efficient ranges (of integers or of Cartesian indices);

- ranges produced by `@range` (resp. `@reverse_range`) always have positive
  (resp. negative) steps;

- operators `+` and `-` can be used to [*shift*](#shift-operations) index
  ranges;

- operator `∩` and method `intersect` yield the [intersection](#intersecting)
  of ranges with ranges, of ranges with indices, or of indices with indices;

- operator `±` can be used to [*stretch*](#stretching) ranges or to produce
  symmetric ranges;

- operator `∓` can be used to [*shrink*](#shrinking) ranges.

As shown in [*A working example*](#a-working-example) below, these rules are
useful for writing readable ranges in `for` loops without sacrificing
efficiency.


### Definitions

In `IndexingTools`, if *indices* are integers, *ranges* means ranges of
integers (of super-type `OrdinalRange{Int}{Int}`); if *indices* are Cartesian
indices, *ranges* means ranges of Cartesian indices (of super-type
`CartesianIndices`).


### Shift operations

In `@range` and `@reverse_range` expressions, an index range `R` can be shifted
with the operators `+` and `-` by an amount specified by an index `I`:

```julia
@range R + I -> S # J ∈ S is equivalent to J - I ∈ R
@range R - I -> S # J ∈ S is equivalent to J + I ∈ R

@range I + R -> S # J ∈ S is equivalent to J - I ∈ R
@range I - R -> S # J ∈ S is equivalent to I - J ∈ R
```

Integer-valued ranges can be shifted by an integer offset:

```julia
@range (3:6) + 1    ->  4:7    # (2:6) .+ 1    ->  4:7
@range 1 + (3:6)    ->  4:7    # (2:6) .+ 1    ->  4:7
@range (2:4:10) + 1 ->  3:4:11 # (2:4:10) .+ 1 ->  3:4:11
@range (3:6) - 1    ->  2:5    # (3:6) .- 1    ->  2:5
@range 1 - (3:6)    -> -5:-2   # 1 .- (3:6)    -> -2:-1:-5
```

This is like using the broadcasting operators `.+` and `.-` except that the
result is an `Int`-valued range and that the step sign is kept positive (as in
the last above example).

The `@reverse_macro` yields ranges with negative steps:

```julia
@reverse_range (3:6) + 1 ->  7:-1:4
@reverse_range 1 + (3:6) ->  7:-1:4
@reverse_range (3:6) - 1 ->  5:-1:1
@reverse_range 1 - (3:6) -> -1:-1:-5
```

Cartesian ranges can be shifted by a Cartesian index (without penalties on the
execution time and, usually, no extra allocations):

```julia
@range CartesianIndices((2:6, -1:2)) + CartesianIndex(1,3)
# -> CartesianIndices((3:7, 2:5))
@range CartesianIndex(1,3) + CartesianIndices((2:6, -1:2))
# -> CartesianIndices((3:7, 2:5))
@range CartesianIndices((2:6, -1:2)) - CartesianIndex(1,3)
# -> CartesianIndices((1:5, -4:-1))
@range CartesianIndex(1,3) - CartesianIndices((2:6, -1:2))
# -> CartesianIndices((-5:-1, 1:4))
```

This is similar to the broadcasting operators `.+` and `.-` except that a
lightweight instance of `CartesianIndices` with positive increment is always
produced.


### Intersecting

In `@range` and `@reverse_range` expressions, the operator `∩` (obtained by
typing `\cap` and pressing the `[tab]` key at the REPL) and the method
`intersect` yield the intersection of ranges with ranges, of ranges with
indices, or of indices with indices.

The intersection of indices, say `I` and `J`, yield a range `R` (empty if the
integers are different):

```julia
@range I ∩ J -> R   # R = {I} if I == J, R = {} else
```

Examples:

```julia
@range 3 ∩ 3 -> 3:3
@range 3 ∩ 2 -> 1:0  # empty range
@range CartesianIndex(3,4) ∩ CartesianIndex(3,4) -> CartesianIndices((3:3,4:4))
```

The intersection of an index range `R` and an index `I` yields an index range
`S` that is either empty or a singleton:

```julia
@range R ∩ I -> S   # S = {I} if I ∈ R, S = {} else
@range I ∩ R -> S   # idem
```

Examples:

```julia
@range (2:6) ∩ 3     -> 3:3 # a singleton range
@range 1 ∩ (2:6)     -> 1:0 # an empty range
@range (2:6) ∩ (3:7) -> 3:6 # intersection of ranges
@range CartesianIndices((2:4, 5:9)) ∩ CartesianIndex(3,7))
    -> CartesianIndices((3:3, 7:7))
```

These syntaxes are already supported by Julia, but the `@range` macro
guarantees to return an `Int`-valued range with a forward (positive) step.


### Streching

In `@range` and `@reverse_range` expressions, the operator `±` (obtained by
typing `\pm` and pressing the `[tab]` key at the REPL) can be used to
**stretch** ranges or to produce symmetric ranges.

The expression `R ± I` yields the index range `R` stretched by an amount
specified by index `I`:

```julia
@range R ± I -> (first(R) - I):(last(R) + I)
```

where, if `R` is a range of integers, `I` is an integer, and if `R` is a
`N`-dimensional Cartesian, `I` is a `N`-dimensional Cartesian index range.  Not
shown in the above expression, the range step is preserved by the operation
(except that the result has a positive step).

The expression `I ± ΔI` with `I` an index and `ΔI` an index offset yields a
symmetric index range:

```julia
@range I ± ΔI -> (I - ΔI):(I + ΔI)
```

There is no sign correction and the range may be empty.  If `I` and `ΔI` are
two integers, `I ± ΔI` is a range of integers.  If `I` is a `N`-dimensional
Cartesian index, then `I ± ΔI` is a range of Cartesian indices and `ΔI` can be
an integer, a `N`-tuple of integers, or a `N`-dimensional Cartesian index.


### Shrinking

In `@range` and `@reverse_range` expressions, the operator `∓` (obtained by
typing `\mp` and pressing the `[tab]` key at the REPL) can be used to
**shrink** ranges.

The expression `R ∓ I` yields the same result as `@range R ± (-I)`, that is the
index range `R` shrink by an amount specified by index `I`:

```julia
@range R ∓ I -> (first(R) + I):(last(R) - I)
```


## Installation

The `IndexingTools` package can be installed as:

```julia
using Pkg
pkg"add https://github.com/emmt/IndexingTools.jl"
```

You may also consider using [my custom
registry](https://github.com/emmt/EmmtRegistry):

```julia
using Pkg
pkg"registry add General" # if no general registry has been installed yet
pkg"registry add https://github.com/emmt/EmmtRegistry" # if not yet added
pkg"add IndexingTools"
```


## A working example

`IndexingTools` may be very useful to write readable expressions in ranges used
by `for` loops.  For instance, suppose that you want to compute a **discrete
correlation** of `A` by `B` as follows:

$$
C[i] = \sum_{j} A[j] B[j-i]
$$

and for all valid indices `i` and `j`.  Assuming `A`, `B` and `C` are abstract
vectors, the Julia equivalent code is:

```julia
for i ∈ eachindex(C)
    s = zero(T)
    j_first = max(firstindex(A), firstindex(B) + i)
    j_last = min(lastindex(A), lastindex(B) + i)
    for j ∈ j_first:j_last
        s += A[j]*B[j-i]
    end
    C[i] = s
end
```

where `T` is a suitable type, say `T = promote_type(eltype(A), eltype(B))`.
The above expressions of `j_first` and `j_last` are to ensure that `A[j]` and
`B[j-i]` are in bounds.  The same code for multidimensional arrays writes:

```julia
for i ∈ CartesianIndices(C)
    s = zero(T)
    j_first = max(first(CartesianIndices(A)),
                  first(CartesianIndices(B)) + i)
    j_last = min(last(CartesianIndices(A)),
                 last(CartesianIndices(B)) + i)
    for j ∈ j_first:j_last
        s += A[j]*B[j-i]
    end
    C[i] = s
end
```

now `i` and `j` are multidimensional Cartesian indices and Julia already helps
a lot by making such a code applicable whatever the number of dimensions.  Note
that the syntax `j_first:j_last` is supported for Cartesian indices since Julia
1.1.  There is more such syntactic sugar and using the broadcasting operator
`.+` and the operator `∩` (a shortcut for the function `intersect`), the code
can be rewritten as:

```julia
for i ∈ CartesianIndices(C)
    s = zero(T)
    for j ∈ CartesianIndices(A) ∩ (CartesianIndices(B) .+ i)
        s += A[j]*B[j-i]
    end
    C[i] = s
end
```

which is not less efficient and yet much more readable.  Indeed, the statement

```julia
for j ∈ CartesianIndices(A) ∩ (CartesianIndices(B) .+ i)
```

makes it clear that the loop is for all indices `j` such that `j ∈
CartesianIndices(A)` and `j - i ∈ CartesianIndices(B)` which is required to
have `A[j]` and `B[j-i]` in bounds.   The same principles can be applied to the
uni-dimensional code:

```julia
for i ∈ eachindex(C)
    s = zero(T)
    for j ∈ eachindex(A) ∩ (eachindex(B) .+ i)
        s += A[j]*B[j-i]
    end
    C[i] = s
end
```

Now suppose that you want to compute the **discrete convolution** instead:

$$
C[i] = \sum_{j} A[j] B[i-j]
$$

Then, the code for multi-dimensional arrays writes:

```julia
for i ∈ CartesianIndices(C)
    s = zero(T)
    for j ∈ CartesianIndices(A) ∩ (i .- CartesianIndices(B))
        s += A[j]*B[i-j]
    end
    C[i] = s
end
```

because you want to have `j ∈ CartesianIndices(A)` and `i - j ∈
CartesianIndices(B)`, the latter being equivalent to `j ∈ i -
CartesianIndices(B)`.

This simple change however results in **a dramatic slowdown** because the
expression `i .- CartesianIndices(B)` yields an array of Cartesian indices
while the expression `CartesianIndices(B) .- i` yields an instance of
`CartesianIndices`.

Using the `@range` macro of `IndexingTools`, the discrete correlation and
discrete convolution write:

```julia
# Discrete correlation.
for i ∈ CartesianIndices(C)
    s = zero(T)
    for j ∈ @range CartesianIndices(A) ∩ (CartesianIndices(B) + i)
        s += A[j]*B[j-i]
    end
    C[i] = s
end

# Discrete convolution.
for i ∈ CartesianIndices(C)
    s = zero(T)
    for j ∈ @range CartesianIndices(A) ∩ (i - CartesianIndices(B))
        s += A[j]*B[i-j]
    end
    C[i] = s
end
```

which do not require the broadcasting operators `.+` and `.-` and which do not
have the aforementioned issue.  Using the macros `@range` and `@reverse_range`
have other advantages:

- The result is guaranteed to be `Int`-valued (needed for efficient indexing).

- The *step*, that is the increment between consecutive indices, in the result
  has a given direction: `@range` yields a positive step while `@reverse_range`
  yields a negative step.

- The syntax of range expressions is simplified and extended for other
  operators (like `±` for stretching or `∓` for shrinking) that are not
  available in the base Julia.  This syntax can be extended as the package is
  developed without disturbing other packages (i.e., no type-piracy).
