CREATE MATERIALIZED VIEW Monhtly_summary 
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
WITH MS AS (
    SELECT
        MA.aircraftRegistration,
        MD.model,
        TM.month,
        TM.year,
        SUM(CASE WHEN MA.scheduled = '1' THEN MA.DOS ELSE 0 END) AS ADOSS,
        SUM(CASE WHEN MA.scheduled = '0' THEN MA.DOS ELSE 0 END) AS ADOSU
    FROM
        Maintenance MA
        INNER JOIN Time TM ON MA.time_id = TM.time_id
        INNER JOIN Model MD ON MA.aircraftRegistration = MD.aircraftRegistration
    GROUP BY
        MA.aircraftRegistration,
        MD.model,
        TM.month,
        TM.year
),
L AS (
    SELECT
        LB.aircraftRegistration,
        MD.model,
        TM.month,
        TM.year,
        COUNT(LB.reporteur_id) AS total_logbook_count,
        COUNT(CASE WHEN rLB.eporteur_class = 'PIREP' THEN 1 END) AS pilot_logbook_count
    FROM
        LogBook LB
        INNER JOIN Time TM ON LB.time_id = TM.time_id
        INNER JOIN Model MD ON LB.aircraftRegistration = MD.aircraftRegistration
    GROUP BY
        LB.aircraftRegistration,
        MD.model,
        TM.month,
        TM.year
),
F AS (
    SELECT 
        DS.aircraftRegistration,
        DS.model,
        DS.month,
        DS.year,
        SUM(DS.flight_hours) AS flight_hours,
        SUM(DS.total_operations) AS total_operations,
        SUM(DS.CN) AS CN,
        SUM(DS.DY) AS DY,
        SUM(DS.TDD) AS TDD
    FROM Daily_summary DS
    GROUP BY
        DS.aircraftRegistration,
        DS.model,
        DS.month, 
        DS.year
),
Keys AS (
    SELECT DISTINCT
        aircraftRegistration,
        model,
        month,
        year
    FROM (
        SELECT aircraftRegistration, model, month, year FROM MS
        UNION
        SELECT aircraftRegistration, model, month, year FROM L
        UNION
        SELECT aircraftRegistration, model, month, year FROM F
    )
)
SELECT
    K.aircraftRegistration,
    K.model,
    K.month,
    K.year,

    -- Maintenance Metrics (ADOS, ADIS, etc)
    M.ADOS,
    M.ADOSS,
    M.ADOSU,
    M.ADIS,

    -- Delays and Cancellations
    F.DY AS DelayCount,
    F.TDD AS TotalDelayDuration,
    F.CN AS CancellationCount,

    -- Logbook Metrics
    L.total_logbook_count,
    L.pilot_logbook_count,
    
    -- Flight Hours and Total Operations
    F.flight_hours,
    F.total_operations,

    -- Daily Utilization (DU) = flight_hours / ADIS
    
    -- Daily Cycles (DC) = total_operations / ADIS
    
    -- Delay Rate (DYR) = (DY / total_operations) * 100
        
    -- Cancellation Rate (CNR) = (CN / total_operations) * 100
        
    -- Technical Dispatch Reliability (TDR) = 100 - ((DY + CN) / total_operations ) * 100
        
    -- Average Delay Duration (AD) = (TotalDelayDuration / DY) * 10
    
    -- Report Rate per Hour (RRh) = 1000 * total_logbook_count / total_flight_hours
    
    -- Report Rate per Cycle (RRc) = 100 * total_logbook_count / total_departures
    
    -- Pilot Report Rate per Hour (PRRh) = 1000 * pilot_logbook_count / total_flight_hours
    
    -- Pilot Report Rate per Cycle (PRRc) = 100 * pilot_logbook_count / total_departures

        
FROM
    Keys K
    LEFT JOIN
    (
        SELECT
            MS.aircraftRegistration,
            MS.model,
            MS.month,
            MS.year,
            MS.ADOSS,
            MS.ADOSU,
            -- Calculate ADOS as the sum of ADOSS and ADOSU
            MS.ADOSS + MS.ADOSU AS ADOS,
            -- Use ADOS to calculate ADIS
            EXTRACT(
                DAY FROM LAST_DAY(TO_DATE(LPAD(MS.month, 2, '0') || '-' || MS.year, 'MM-YYYY'))
            ) - NVL(MS.ADOSS + MS.ADOSU, 0) AS ADIS
        FROM MS
    ) M
    ON K.aircraftRegistration = M.aircraftRegistration
       AND K.model = M.model 
       AND K.month = M.month 
       AND K.year = M.year
    LEFT JOIN L
    ON K.aircraftRegistration = L.aircraftRegistration
       AND K.model = L.model
       AND K.month = L.month
       AND K.year = L.year
    LEFT JOIN F
    ON K.aircraftRegistration = F.aircraftRegistration
       AND K.model = F.model
       AND K.month = F.month
       AND K.year = F.year;
