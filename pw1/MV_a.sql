CREATE MATERIALIZED VIEW Daily_summary
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
    SELECT 
        FL.aircraftRegistration,
        Model.model,
        Time.day,
        Time.month,
        Time.year,
        SUM(FL.FlightHours) AS flight_hours,
        COUNT(CASE WHEN FL.cancelled = '0' THEN 1 END) AS total_operations,
        COUNT(CASE WHEN FL.cancelled = '1' THEN 1 END) AS CN,
        COUNT(CASE WHEN FL.delay_duration BETWEEN 15 AND 360 THEN 1 END) AS DY,
        SUM(CASE WHEN FL.delay_duration BETWEEN 15 AND 360 THEN FL.delay_duration ELSE 0 END) AS TDD
    FROM Flight FL
	    INNER JOIN Time ON FL.time_id = Time.time_id
	    INNER JOIN Model ON FL.aircraftRegistration = Model.aircraftRegistration
    GROUP BY
        FL.aircraftRegistration, 
        Model.model,
        Time.day,
        Time.month,
        Time.year;
	