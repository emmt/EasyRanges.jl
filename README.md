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
The above expressions of `j_first` and `j_last` are to make sure that `A[j]`
and `B[j-i]` are in bounds.  The same code for multidimensional arrays writes:

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
expression `i .- CartesianIndices(B)` yields a vector of Cartesian indices
while the expression `CartesianIndices(B) .- i` yields an instance of
`CartesianIndices`.

Using the `@range` macro, the discrete correlation and discrete convolution
write:

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

- The increment in the result has a given direction: `@range` yields a positive
  step while `@reverse_range` yields a negative step.

- The syntax of range expressions is simplified and extended for other
  operators (like `±` for stretching or `∓` for shrinking) that are not
  available in the base Julia.  This syntax may be extended as the package is
  developed without perturbing other packages (i.e., no type-piracy).


## Usage

```julia
using IndexingTools
```

### Combine ranges and integers

Combining a range `r` and an integer `i` as `r + i`, `r - i`, `r ∩ i`,
etc. yields a range with a forward (positive) step.

The following syntaxes are already supported by Julia, but the `@range` macro
guarantees to return an `Int`-valued range:

```julia
@range (2:6) ∩ 3     -> 3:3 # a singleton range
@range 1 ∩ (2:6)     -> 1:0 # an empty range
@range (2:6) ∩ (3:7) -> 3:6 # intersection of ranges
```

Ranges can be shifted by an integer offset:

```julia
@range (2:6) + 1 -> 3:7  # like (2:6) .+ 1 -> 3:7
@range (2:6) - 1 -> 1:5  # like (2:6) .- 1 -> 1:5
```

This is like `.+` and `.-` operator except that the result is an `Int` valued
rarge and that step sign is preserved if a range is subtracted to an integer:

```julia
@range 1 - (2:6) -> -5:-1
1 .- (2:6)       -> -1:-1:-5
```

### Combine Cartesian indices

The intersection of a Cartesian indices `R` and a Cartesian index `I` yields an
instance `S` of `CartesianIndices` that is either empty or a singleton:

```julia
@range R ∩ I -> S   #  S = {I} if I ∈ R, S is empty else
@range I ∩ R -> S   # idem
```

Cartesian regions may be shifted (without penalties on the execution time and
no extra allocations):

```julia
@range R + I -> S # ∀ J ∈ S, J - I ∈ R
@range R - I -> S # ∀ J ∈ S, J + I ∈ R

@range I + R -> S # ∀ J ∈ S, J - I ∈ R
@range I - R -> S # ∀ J ∈ S, I - J ∈ R
```

Expression `I ± ΔI` with `I` a `N`-dimensional Cartesian index and `ΔI` an
integer, a `N`-tuple of integers, or a `N`-dimensional Cartesian index yields
the Cartesian indices corresponding to `(I - ΔI):(I + ΔI)` (there is no sign
correction and the region may be empty):

```julia
@range I ± ΔI
```

Conversely `I ∓ ΔI` yields the Cartesian indices corresponding to
`(I + ΔI):(I - ΔI)`
