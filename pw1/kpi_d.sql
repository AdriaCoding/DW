CREATE MATERIALIZED VIEW Logbook_summary
BUILD IMMEDIATE
REFRESH FORCE ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT 
    L.reporteur_id
    L.airport_id
    DS.aircraftRegistration
    DS.model
    CASE 
        WHEN NVL(DS.total_FH), 0) > 0
        THEN 1000 * NVL(L.maintenance_logbook_count, 0) / DS.total_FH
        ELSE 0
    END AS MRRh
    CASE 
        WHEN NVL(DS.total_FO, 0) > 0
        THEN 100 * NVL(L.maintenance_logbook_count, 0) / DS.total_FO
        ELSE 0
    END AS MRRh
FROM
(
    SELECT
        Logbook.aircraftRegistration
        LogBook.airport_id
        LogBook.reporteur_id
    FROM LogBook
    WHERE reporteur_class = 'MAREP'
) AS L
INNER JOIN 
(
    SELECT
        SUM(FH) AS total_FH
        SUM(TO) AS total_FO
        aircraftRegistration
        model
    FROM Daily_Summary
    GROUP BY aircraftRegistration
) AS DS 
ON DS.aircraftRegistration = L.aircraftRegistration
AND 