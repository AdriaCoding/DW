CREATE MATERIALIZED VIEW MONTHLY_SUMMARY 
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
SELECT
    NVL(F.aircraftRegistration, M.aircraftRegistration) AS aircraftRegistration,
    NVL(F.model, M.model) AS model,
    NVL(F.month, M.month) AS month,
    NVL(F.year, M.year) AS year,
       
    -- Aircraft Days In/Out of Service (ADOS, ADIS, etc)
    M.ADOS,
    M.ADOSS,
    M.ADOSU,
    M.ADIS

    -- Daily Utilization (DU) = FH / ADIS
    CASE
        WHEN NVL(M.ADIS, 0) > 0
        THEN F.FH / ADIS
        ELSE 0
    END AS DU

    -- Daily Cycles (DC) = TotalOperations / ADIS
    CASE
        WHEN NVL(M.ADIS, 0) > 0
        THEN F.TotalOperations / ADIS
        ELSE 0
    END AS DC

    -- Delay Rate (DYR) = (DY / TotalOperations) * 100
    CASE 
        WHEN NVL(F.TotalOperations, 0) > 0 
        THEN (NVL(F.DY, 0) / NVL(F.TotalOperations, 0)) * 100 
        ELSE 0 
    END AS DYR,
    
    -- Cancellation Rate (CNR) = (CN / TotalOperations) * 100
    CASE 
        WHEN NVL(F.TotalOperations, 0) > 0 
        THEN (NVL(F.CN, 0) / NVL(F.TotalOperations, 0)) * 100 
        ELSE 0 
    END AS CNR,
    
    -- Technical Dispatch Reliability (TDR) = 100 - ((DY + CN) / TotalOperations ) * 100
    CASE 
        WHEN NVL(F.TotalOperations, 0) > 0 
        THEN 100 - ((NVL(F.DY, 0) + NVL(F.CN, 0)) / NVL(F.TotalOperations, 0)) * 100 
        ELSE 0 
    END AS TDR,
    
    -- Average Delay Duration (AD) = (TotalDelayDuration / DY) * 10
    CASE 
        WHEN NVL(F.DY, 0) > 0 
        THEN (NVL(F.TotalDelayDuration, 0) / NVL(F.DY, 0)) * 10 
        ELSE 0 
    END AS AD
    
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
            SUM(CASE WHEN FL.delay_duration BETWEEN 15 AND 360 THEN FL.delay_duration ELSE 0 END) AS TotalDelayDuration
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
            MA.aircraftRegistration,
            MD.model,
            TM.month,
            TM.year,
            SUM(CASE WHEN MA.scheduled = '1' THEN MA.DOS ELSE 0 END) AS ADOSS,
            SUM(CASE WHEN MA.scheduled = '0' THEN MA.DOS ELSE 0 END) AS ADOSU
            -- Is this summation correct?
            ADOSS + ADOSU AS ADOS,
            -- Obtain ADIS as the complementary of ADOS
            EXTRACT(
                DAY FROM LAST_DAY(TO_DATE(TM.month || '-' || TM.year, 'MM-YYYY'))
            ) - NVL(ADOS, 0)) AS ADIS,
    
        FROM
            Maintenance MA
            INNER JOIN Time TM ON MA.time_id = TM.time_id
            INNER JOIN Model MD ON MA.aircraftRegistration = MD.aircraftRegistration
        GROUP BY
            MA.aircraftRegistration,
            MD.model,
            TM.month,
            TM.year
    ) M
    ON F.aircraftRegistration = M.aircraftRegistration 
       AND F.month = M.month 
       AND F.year = M.year;

