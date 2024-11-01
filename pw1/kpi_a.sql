CREATE MATERIALIZED VIEW Daily_Summary
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
	SELECT 
        Flight.aircraftRegistration,
        Model.model,
        Time.day,
        Time.month,
        Time.year,
        SUM(Flight.FlightHours) AS FH,
        COUNT(Flight.time_id) AS "TO"
	FROM 
        Flight 
	    INNER JOIN Time ON Flight.time_id = Time.time_id
	    INNER JOIN Model ON Flight.aircraftRegistration = Model.aircraftRegistration
	WHERE Flight.cancelled = 0
	GROUP BY Flight.aircraftRegistration, Model.model, Time.day, Time.month, Time.year;
	