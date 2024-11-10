# User visible changes in `EasyRanges`

## Version 0.1.3

New features:

- The method `EasyRanges.normalize` is not exported but may be extended by other packages
  to implement their own index or index range objects in `EasyRanges`.

- In the `@range` or `@reverse_range` expression, the syntax `$(subexpr)` may be used to
  prevent any sub-expression `subexpr` from being interpreted as a range expression.

Breaking changes:

- Expressions in `@range` and `@reverse_range` should only involve array indices (linear
  indices, i.e. integers, or multi-dimensional Cartesian indices) or objects representing
  ranges of indices. All such arguments are filtered by the `EasyRanges.normalize` method
  which shall return an equivalent object in a canonical form. If `EasyRanges.normalize`
  is not implemented for a given type, it is considered that the object is invalid as an
  index or as an index range. There were no such restrictions in the previous version and
  expressions involving non-index objects could possibly work but this was a source of
  confusion. Now the syntax `$(subexpr)` should be used to protect sub-expressions from
  being interpreted as a range expression.

The following changes only concern internal methods and types, they should not affect the end user:

- Private aliases `EasyRanges.ContiguousRange` and `EasyRanges.CartesianBox{N}` have been
  suppressed.

- Internal methods `EasyRange.plus`, `EasyRange.plus`, etc. no longer attempt to yield
  ranges with a positive step. This simplifies the implementation and is not necessary
  since the final processing pass by the public macros `@range` and `@reverse_range`
  consists in calling `EasyRange.forward` or `EasyRange.backward` which take care of the
  sign of the step. This also fixes bugs in the stretching and shrinking (`±` and `∓`)
  operators.

- Internal method `EasyRange.to_int` is no longer used and has been suppressed. It is
  superseded by `EasyRange.normalize`.

- Internal method `EasyRange.to_type` is no longer used and has been suppressed. It is
  superseded by [`TypeUtils.as`](https://github.com/emmt/TypeUtils.jl) and, to some
  extend, by `EasyRange.normalize`.

- Internal methods `EasyRange.first_last` and `EasyRange.first_step_last` are no longer
  used and have been suppressed.
