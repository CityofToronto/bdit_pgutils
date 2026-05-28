--query to return random standup order.
--set as a macro for quick access

SELECT string_agg(r_n, chr(10))
FROM (
    SELECT rank() OVER (ORDER BY random()) || '. ' || unnest AS r_n
    FROM UNNEST('{Alice, Bob, Chris, Daniel}'::text[])
) AS r_ns;