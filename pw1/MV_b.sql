CREATE MATERIALIZED VIEW Monthly_summary 
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
WITH MaintenanceSummary AS (
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
)
SELECT
    NVL(F.aircraftRegistration, M.aircraftRegistration) AS aircraftRegistration,
    NVL(F.model, M.model) AS model,
    NVL(F.month, M.month) AS month,
    NVL(F.year, M.year) AS year,
       
    -- Aircraft Days In/Out of Service (ADOS, ADIS, etc)
    M.ADOS,
    M.ADOSS,
    M.ADOSU,
    M.ADIS,

    -- Delays and Cancellations
    F.DY AS DelayCount,
    F.TDD AS TotalDelayDuration,
    F.CN AS CancellationCount,

    -- Flight Hours and Total Operations
    F.flight_hours,
    F.total_operations,
    
    -- Daily Utilization (DU) = flight_hours / ADIS
    
    -- Daily Cycles (DC) = total_operations / ADIS
    
    -- Delay Rate (DYR) = (DY / total_operations) * 100
        
    -- Cancellation Rate (CNR) = (CN / total_operations) * 100
        
    -- Technical Dispatch Reliability (TDR) = 100 - ((DY + CN) / total_operations ) * 100
        
    -- Average Delay Duration (AD) = (TotalDelayDuration / DY) * 10

        
FROM
    (
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
            DS.month, 
            DS.year, 
            DS.aircraftRegistration,
            DS.model
    ) F
    FULL OUTER JOIN
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
        FROM
            MaintenanceSummary MS
    ) M
    ON F.aircraftRegistration = M.aircraftRegistration 
       AND F.month = M.month 
       AND F.year = M.year;
