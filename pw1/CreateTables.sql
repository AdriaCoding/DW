CREATE TABLE Model (
	aircraftRegistration CHAR(6) NOT NULL PRIMARY KEY,
	model VARCHAR(15),
	manufacturer VARCHAR(10)
);

CREATE TABLE Time (
	time_id INTEGER NOT NULL PRIMARY KEY,
	day SMALLINT,
	month SMALLINT,
	year SMALLINT
);

CREATE TABLE Flight (
    aircraftRegistration CHAR(6) NOT NULL REFERENCES Model(aircraftRegistration),
    time_id INTEGER NOT NULL REFERENCES Time(time_id),
    airport_id CHAR(3) NOT NULL,
    FlightHours NUMBER(5,2),
    delay_duration NUMBER(5,2),
    cancelled CHAR(1) CHECK (cancelled in (0,1))
);

CREATE INDEX time_id_flight_index on Flight (time_id);

CREATE TABLE LogBook (
    aircraftRegistration CHAR(6) NOT NULL REFERENCES Model(aircraftRegistration),
    time_id INTEGER NOT NULL REFERENCES Time(time_id),
    airport_id CHAR(3),
    reporteur_id SMALLINT NOT NULL,
    reporteur_class CHAR(5) NOT NULL CHECK (reporteur_class IN ('PIREP', 'MAREP'))
);

CREATE INDEX time_id_logbook_index on LogBook (time_id);

CREATE TABLE Maintenance (
    aircraftRegistration CHAR(6) NOT NULL REFERENCES Model(aircraftRegistration),
    time_id INTEGER NOT NULL REFERENCES Time(time_id),
    airport_id CHAR(3),
    scheduled CHAR(1) CHECK (scheduled in (0,1)),
    DOS NUMBER(5,2)
);

CREATE INDEX time_id_maintenance_index on Maintenance (time_id);

CREATE MATERIALIZED VIEW Daily_Summary
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
	SELECT Flight.aircraftRegistration, Model.model, Time.day, Time.month, Time.year, SUM(Flight.FlightHours) AS FH, COUNT(Flight.time_id) AS "TO"
	FROM Flight 
	INNER JOIN Time
	ON Flight.time_id = Time.time_id
	INNER JOIN Model
	ON Flight.aircraftRegistration = Model.aircraftRegistration
	WHERE Flight.cancelled = 0
	GROUP BY Flight.aircraftRegistration, Model.model, Time.day, Time.month, Time.year;
	
CREATE MATERIALIZED VIEW Monthly_Summary
BUILD IMMEDIATE
REFRESH FORCE
ON DEMAND
ENABLE QUERY REWRITE
AS
	SELECT Maintenance.aircraftRegistration, Model.model, Time.month, Time.YEAR, SUM(Maintenance.DOS)/COUNT(Time.Day) AS ADOS
	FROM Maintenance 
	INNER JOIN Time
	ON Maintenance.time_id = Time.time_id
	INNER JOIN Model
	ON Maintenance.aircraftRegistration = Model.aircraftRegistration
	INNER JOIN Daily_Summary
	ON Time.month = Daily_Summary.month AND Time.year = Daily_Summary.year
	GROUP BY Maintenance.aircraftRegistration, Model.model, Time.month, Time.year;



