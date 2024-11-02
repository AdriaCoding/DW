CREATE MATERIALIZED VIEW Logbook_summary
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
	L.aircraftRegistration,
    DS.model,
	L.month,
	L.year,

    DS.total_flight_hours,
    L.total_logbook_count,
    DS.total_departures,
    L.pilot_logbook_count,

    -- Report Rate per Hour (RRh) = 1000 * total_logbook_count / total_flight_hours
    -- Report Rate per Cycle (RRc) = 100 * total_logbook_count / total_departures
    -- Pilot Report Rate per Hour (PRRh) = 1000 * pilot_logbook_count / total_flight_hours
    -- Pilot Report Rate per Cycle (PRRc) = 100 * pilot_logbook_count / total_departures
  	
FROM
    (
        SELECT
            L.aircraftRegistration,
            TM.month AS month,
            TM.year AS year,
           	COUNT(reporteur_id) AS total_logbook_count
           	COUNT(CASE WHEN reporteur_class = 'PIREP' THEN 1 END) AS pilot_logbook_count,
        FROM
            Logbook L
            INNER JOIN Time TM ON L.time_id = TM.time_id
        GROUP BY
        	L.aircraftRegistration,
            TM.month,
            TM.year
    ) L
    INNER JOIN
    (
    	SELECT
    		DS.aircraftRegistration,
    		DS.model,
    		DS.month,
    		DS.year,
    		SUM(DS.FH) AS total_flight_hours,
    		SUM(DS."TO") AS total_departures
    	FROM 
    		DAILY_SUMMARY DS
    	GROUP BY
    		DS.aircraftRegistration,
    		DS.model,
    		DS.month,
    		DS.year   	
    ) DS
    ON L.aircraftRegistration = DS.aircraftRegistration
        AND L.month = DS.month
        AND L.year = DS.YEAR;
