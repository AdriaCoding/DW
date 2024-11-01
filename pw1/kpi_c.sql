CREATE MATERIALIZED VIEW Logbook_summary
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
	L.aircraftRegistration,
    DS.model,
	L.MONTH,
	L.YEAR,
    -- Report Rate per Hour (RRh) = 1000 * Total_Logbook_Count / Total_Flight_Hours
    CASE 
        WHEN NVL(DS.Total_Flight_Hours, 0) > 0 
        THEN 1000 * (NVL(L.Pilot_Logbook_Count, 0) + NVL(L.Maintenance_Logbook_Count, 0))  / DS.Total_Flight_Hours
        ELSE 0 
    END AS RRh,
    
    -- Report Rate per Cycle (RRc) = 100 * Total_Logbook_Count / Total_Departures
    CASE 
        WHEN NVL(DS.Total_Departures, 0) > 0 
        THEN 100 * (NVL(L.Pilot_Logbook_Count, 0) + NVL(L.Maintenance_Logbook_Count, 0))  / DS.Total_Departures
        ELSE 0 
    END AS RRc,
    
    -- Pilot Report Rate per Hour (PRRh) = 1000 * Pilot_Logbook_Count / Total_Flight_Hours
    CASE 
        WHEN NVL(DS.Total_Flight_Hours, 0) > 0 
        THEN 1000 * NVL(L.Pilot_Logbook_Count, 0) / DS.Total_Flight_Hours
        ELSE 0 
    END AS PRRh,
    
    -- Pilot Report Rate per Cycle (PRRc) = 100 * Pilot_Logbook_Count / Total_Departures
    CASE 
        WHEN NVL(DS.Total_Departures, 0) > 0 
        THEN 100 * NVL(L.Pilot_Logbook_Count, 0) / DS.Total_Departures
        ELSE 0 
    END AS PRRc,
    
    -- Maintenance Report Rate per Hour (MRRh) = 1000 * Maintenance_Logbook_Count / Total_Flight_Hours
    CASE 
        WHEN NVL(DS.Total_Flight_Hours, 0) > 0 
        THEN 1000 * NVL(L.Maintenance_Logbook_Count, 0) / NVL(DS.Total_Flight_Hours, 0)
        ELSE 0 
    END AS MRRh,
    
    -- Maintenance Report Rate per Cycle (MRRc) = 100 * Maintenance_Logbook_Count / Total_Departures
    CASE 
        WHEN NVL(DS.Total_Departures, 0) > 0 
        THEN 100 * NVL(L.Maintenance_Logbook_Count, 0) / NVL(DS.Total_Departures, 0)
        ELSE 0 
    END AS MRRc 	
	
FROM
    (
        SELECT
            L.aircraftRegistration,
            TM.MONTH AS month,
            TM.YEAR AS year,
           	COUNT(CASE WHEN reporteur_class = 'PIREP' THEN 1 END) AS Pilot_Logbook_Count,
           	COUNT(CASE WHEN reporteur_class = 'MAREP' THEN 1 END) AS Maintenance_Logbook_Count
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
    		DS.Model,
    		DS.MONTH,
    		DS.YEAR,
    		SUM(DS.FH) AS Total_Flight_Hours,
    		SUM(DS."TO") AS Total_Departures
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
