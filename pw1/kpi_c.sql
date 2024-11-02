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
    -- Report Rate per Hour (RRh) = 1000 * total_logbook_count / total_flight_hours
    CASE 
        WHEN NVL(DS.total_flight_hours, 0) > 0 
        THEN 1000 * NVL(L.total_logbook_count, 0)   / DS.total_flight_hours
        ELSE 0 
    END AS RRh,
    
    -- Report Rate per Cycle (RRc) = 100 * total_logbook_count / total_departures
    CASE 
        WHEN NVL(DS.total_departures, 0) > 0 
        THEN 100 * NVL(L.total_logbook_count, 0)  / DS.total_departures
        ELSE 0 
    END AS RRc,
    
    -- Pilot Report Rate per Hour (PRRh) = 1000 * pilot_logbook_count / total_flight_hours
    CASE 
        WHEN NVL(DS.total_flight_hours, 0) > 0 
        THEN 1000 * NVL(L.pilot_logbook_count, 0) / DS.total_flight_hours
        ELSE 0 
    END AS PRRh,
    
    -- Pilot Report Rate per Cycle (PRRc) = 100 * pilot_logbook_count / total_departures
    CASE 
        WHEN NVL(DS.total_departures, 0) > 0 
        THEN 100 * NVL(L.pilot_logbook_count, 0) / DS.total_departures
        ELSE 0 
    END AS PRRc
	
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
