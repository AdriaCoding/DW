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
    DS.total_flight_hours,
    DS.total_departures,
    -- Maintenance Report Rate per Hour (MRRh) = 1000 * Maintenance_Logbook_Count / Total_Flight_Hours
    -- Maintenance Report Rate per Cycle (MRRc) = 100 * Maintenance_Logbook_Count / Total_Departures
FROM
(
    SELECT
        Logbook.aircraftRegistration,
        LogBook.airport_id,
        COUNT(CASE WHEN reporteur_class = 'MAREP' THEN 1 END) AS maintenance_logbook_count
    FROM LogBook
    GROUP BY LogBook.airport_id, LogBook.aircraftRegistration
) AS L
INNER JOIN 
(
    SELECT
        SUM(flight_hours) AS total_flight_hours,
        SUM(departures) AS total_departures,
        aircraftRegistration,
        model   
    FROM Daily_Summary
    GROUP BY DS.aircraftRegistration
) AS DS 
ON DS.aircraftRegistration = L.aircraftRegistration;