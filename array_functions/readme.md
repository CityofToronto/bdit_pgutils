
- [Overview](#overview)
  - [create-function-array\_intersect.sql](#create-function-array_intersectsql)
  - [function-array\_diff.sql](#function-array_diffsql)

# Overview
Functions for manipulating arrays.

## [create-function-array_intersect.sql](create-function-array_intersect.sql)
`array_intersect` Finds the intersection between two arrays.
Also includes aggregate function `array_intersect_agg` to find intersection between any number of arrays.

## [function-array_diff.sql](function-array_diff.sql)
Finds the difference between two arrays. Accounts for nulls.
