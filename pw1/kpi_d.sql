CREATE MATERIALIZED VIEW Marep_rate_summary
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
    L.airport_id,
    DS.aircraftRegistration,
    DS.model,
    L.maintenance_logbook_count,
    DS.total_FH,
    DS.total_FO,
    
    -- Maintenance Report Rate per Hour (MRRh) = 1000 * Maintenance_Logbook_Count / Total_Flight_Hours
    CASE 
        WHEN NVL(DS.total_FH, 0) > 0
        THEN 1000 * NVL(L.maintenance_logbook_count, 0) / DS.total_FH
        ELSE 0
    END AS MRRh,

    -- Maintenance Report Rate per Cycle (MRRc) = 100 * Maintenance_Logbook_Count / Total_Departures
    CASE 
        WHEN NVL(DS.total_FO, 0) > 0
        THEN 100 * NVL(L.maintenance_logbook_count, 0) / DS.total_FO
        ELSE 0
    END AS MRRc,
FROM
(
    SELECT
        Logbook.aircraftRegistration,
        LogBook.airport_id,
        COUNT(CASE WHEN reporteur_class = 'MAREP' THEN 1 END) AS maintenance_logbook_count,
    FROM LogBook
    GROUP BY LogBook.airport_id, LogBook.aircraftRegistration
) AS L
INNER JOIN 
(
    SELECT
        SUM(FH) AS total_FH,
        SUM(TO) AS total_FO,
        aircraftRegistration,
        model,
    FROM Daily_Summary
    GROUP BY DS.aircraftRegistration
) AS DS 
ON DS.aircraftRegistration = L.aircraftRegistration;