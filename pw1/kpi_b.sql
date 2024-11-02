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
    F.FH,
    F.TotalOperations AS "TO",
    
    -- Daily Utilization (DU) = FH / ADIS
    
    -- Daily Cycles (DC) = TotalOperations / ADIS
    
    -- Delay Rate (DYR) = (DY / TotalOperations) * 100
        
    -- Cancellation Rate (CNR) = (CN / TotalOperations) * 100
        
    -- Technical Dispatch Reliability (TDR) = 100 - ((DY + CN) / TotalOperations ) * 100
        
    -- Average Delay Duration (AD) = (TotalDelayDuration / DY) * 10

        
FROM
    (
        SELECT
            FL.aircraftRegistration,
            MD.model,
            TM.month,
            TM.year,
            SUM(FL.FlightHours) AS FH,
            COUNT(CASE WHEN FL.cancelled = '0' THEN 1 END) AS TotalOperations,
            COUNT(CASE WHEN FL.cancelled = '1' THEN 1 END) AS CN,
            COUNT(CASE WHEN FL.delay_duration BETWEEN 15 AND 360 THEN 1 END) AS DY,
            SUM(CASE WHEN FL.delay_duration BETWEEN 15 AND 360 THEN FL.delay_duration ELSE 0 END) AS TDD
        FROM
            Flight FL
            INNER JOIN Time TM ON FL.time_id = TM.time_id
            INNER JOIN Model MD ON FL.aircraftRegistration = MD.aircraftRegistration
        GROUP BY
            FL.aircraftRegistration,
            MD.model,
            TM.month,
            TM.year
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
