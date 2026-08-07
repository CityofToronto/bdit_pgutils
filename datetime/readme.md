- [Overview](#overview)
  - [create-function-is\_weekend\_or\_holiday.sql](#create-function-is_weekend_or_holidaysql)
  - [datetime\_bin\_15.sql](#datetime_bin_15sql)
  - [datetime\_bin.sql](#datetime_binsql)
  - [datetime\_bin\_ceil.sql](#datetime_bin_ceilsql)
  - [timerange.sql](#timerangesql)
  - [to\_month.sql](#to_monthsql)

# Overview
Helper functions relating to dates and times.

## [create-function-is_weekend_or_holiday.sql](create-function-is_weekend_or_holiday.sql)
Returns True if date is a weekend or holiday.

## [datetime_bin_15.sql](datetime_bin_15.sql)
Round down to 15 minutes.

## [datetime_bin.sql](datetime_bin.sql)
Rounds a timestamp down to a certain number of minutes, ie. 15 minutes or hourly.

## [datetime_bin_ceil.sql](datetime_bin_ceil.sql)
Round **up** to a certain number of mintues, ie. 15 mintues or hourly.
Differs from typical `date_trunc` or above `datetime_bin` in that it uses `ciel`!

## [timerange.sql](timerange.sql)
Timerange data type. 

## [to_month.sql](to_month.sql)
Used to formatting dates for labelling graphs.