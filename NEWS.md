# User visible changes in `EasyRanges`

New features:

- The method `EasyRanges.normalize` is not exported but may be extended by other packages
  to implement their own index or index range objects in `EasyRanges`.

Breaking changes:

- Expressions in `@range` and `@reverse_range` should only involve array indices (linear
  indices, i.e. integers, or multi-dimensional Cartesian indices) or objects representing
  ranges of indices. All such arguments are filtered by the `EasyRanges.normalize` method
  which shall return an equivalent object in a canonical form. If `EasyRanges.normalize`
  is not implemented for a given type, it is considered that the object is invalid as an
  index or as an index range. There was no such restriction in the previous version and
  expressions involving non-index objects could possibly work but this was a source of
  confusion.

The following changes only concern internal methods and types, they should not affect the
end user:

- Private aliases `EasyRanges.ContiguousRange` and `EasyRanges.CartesianBox{N}` have been
  suppressed.

- Internal methods `EasyRange.plus`, `EasyRange.plus`, etc. no longer attempt to yield
  ranges with a positive step. This simplifies the implementation and is not necessary
  since the final processing pass by the public macros `@range` and `@reverse_range`
  consists in calling `EasyRange.forward` or `EasyRange.backward` which take care of the
  sign of the step. This also fixes bugs in the stretching and shrinking (`±` and `∓`)
  operators.

- Unused internal method `EasyRange.to_int` has been suppressed. It is superseded by
  `EasyRange.normalize`.

- Unused internal method `EasyRange.to_type` has been suppressed. It is superseded by
  `TypeUtils.as` and, to some extend, by `EasyRange.normalize`.
