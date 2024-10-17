## DW-Design

Problem of data-driven or bottom up appoach: You might work to save some facts that no one is ever going to use.

Problem of requirement-driven or up bottom approach: users might ask for impossible things

# KPIs pel projecte
#### (a)
1. Flight Hours (FH): hores de vol a detall fins nivell de dies per cada *aircraftRegistration*. Ho calculem a partir de *actualDeparture* i *actualArrival*. Ho treiem de la taula **Flights**

2. Flight Cycles (TO): És un count d'entrades dins de **Flights** amb el mateix *aircraftRegistration* tq *actualDeparture* is NOT NULL.

#### (b)
La resta de metricas han de ser relatives a un mes donat.
3. Aircraft Days Out-of-Service (ADOS): Es pot obtenir de la taula **MaintenanceEvents** mirant la suma de *duration*'s (ALERTA: Esta implementat com a INTERVAL i no com a int o double- cal veure com fer INTERVAL -> number) per *aircraftRegistration*
  - Aircraft Days Out-of-Service Scheduled (ADOSS): aquells tals que *MaintenanceEventKind* in ('Maintenance', 'Revision')

  - Aircraft Days Out-of-Service Unscheduled (ADOSU): aquells tals que *MaintenanceEventKind* in ('Delay', 'Safety', 'AircraftOnGround')

4. Aircraft Days In-Service (ADIS): ~days_in_month(month) - ADOS~. Això ho podem trobar a la taula de slots

5. Daily Utilization (DU): FH/ADIS. El repte és que una mètrica ve de **Flights** i l'altra de **MaintenanceEvents**.

6. Daily Cycles (DC): TO/ADIS. Same as b fore

7. Delay Rate (DYR): Count delays (DY) a **Flights** després dividir per TO i multiplicar per 100.
  - DY = Count(*) WHERE delayCode is not Null AND 15min < (actualDeparture - scheduledDeparture) < 6h

8. Cancellation Rate (CNR): Count cancellations (CN) a **Flights** despres dividir per TO i multiplicar per 100
  - CN = Count(*) WHERE cancelled is True

9. Technical Dispatch Reliability (TDR):**Flights** TDR = 100 - ((DY + CN) / TO ) x 100

10. Average Delay Duration (ADD): Es fer un agregat per average a **Flights**: Avg(actualDeparture) - Avg(scheduledDeparture) WHERE 15min < (actualDeparture - scheduledDeparture) < 6h

#### (c)
Les següents kpis són per aircraft per month:

11. Report Rate per hour (RRh):
RRh = 1000 x (logbook count)/FH (que forma part de la qury a...)
 - logbookCount = SELECT count(*) FROM **TechnicalLogBookOrders** GROUP BY aircraftRegistration
12. Report Rate per cyple (RRc):
RRc = 100 x (logbook count)/(TO)

13. PIREP Rate (PRR)
 - pilot_logbook_count = SELECT count(*) FROM **TechnicalLogBookOrders** WHERE  ReportKind = 'PIREP' GROUP BY aircraftRegistration
 - PRRh =1000 x pilot_logbook_count/FH
 - PRRc = 100 x pilot_logbook_count/TO
#### (d)
Lesúltimes kpis son per persona o aeroport, per aircraft:

maintenance_logbook_count = SELECT count(*) FROM **TechnicalLogBookOrders** WHERE  ReportKind = 'MAREP' GROUP BY aircraftRegistration, reporteurID

14. MRRh =1000 x maintenance_logbook_count/FH
15. MRRc =100 x maintenance_logbook_count/FO

