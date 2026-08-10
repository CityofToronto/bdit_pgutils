- [Overview](#overview)
  - [twochar\_direction](#twochar_direction)
  - [here\_dir\_from\_line](#here_dir_from_line)
  - [direction\_from\_line](#direction_from_line)
  - [cluster\_within](#cluster_within)
  - [clip\_to](#clip_to)

# Overview
GIS helper functions.

## [twochar_direction](./twochar_direction.sql)
Abbreviates travel directions, ie. "Southbound" to "SB".

## [here_dir_from_line](./here_dir_from_line.sql)
Helper function for HERE. Return "T" (to) or "F" (from) given a HERE line geometry.

## [direction_from_line](./direction_from_line.sql)
Returns travel direction given line geometry. See also: https://github.com/CityofToronto/bdit_pgutils/issues/32

## [cluster_within](./cluster_within.sql)
This function performs bottom-up hierarchical clustering on an array of geometries, grouping points that are within a specified radius of each other into clusters, iteratively merging nearest clusters until no two remaining clusters are within 2 × radius of one another.

## [clip_to](./clip_to.sql)
Clips the specified layer in the specified schema to the Toronto boundary.