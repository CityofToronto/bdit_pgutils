-- FUNCTION: ref.is_weekend_or_holiday(date)
-- DROP FUNCTION IF EXISTS ref.is_weekend_or_holiday(date);

CREATE OR REPLACE FUNCTION ref.is_weekend_or_holiday(
    _dt date
)
RETURNS boolean
LANGUAGE 'sql'
COST 100
STABLE PARALLEL SAFE 

RETURN (
  (date_part('isodow'::text, _dt) >= (6)::double precision) --saturday or sunday
  OR (
    --holiday day
    (SELECT hol.holiday FROM ref.holiday hol WHERE (hol.dt = is_weekend_or_holiday._dt)) IS NOT NULL
  )
);

ALTER FUNCTION ref.is_weekend_or_holiday(date) OWNER TO dbadmin;
GRANT EXECUTE ON FUNCTION ref.is_weekend_or_holiday(date) TO bdit_humans;
