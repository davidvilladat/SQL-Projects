DECLARE @startdate DATE = CONCAT(YEAR(GETDATE())-3,'-01-01');
DECLARE @startdate2 DATE = CONCAT(YEAR(GETDATE())-4,'-01-01');
DECLARE @enddate DATE = CAST(GETDATE() AS DATE);
SET DATEFIRST 1;

------------------------------ TABLAS TEMPORALES

-- BASE DE DATOS VUELOS
SELECT FlightNumber,FlightTypeDescription,Carrier
INTO #Flights_BookDepDateANC
FROM FORECAST.parameter.FlightType

-- BASE DE DATOS CANALES
SELECT salesChannel,CanalVenta
INTO #Canales_BookDepDateANC
FROM CANALES.dbo.tbCanalesSegmentacion

-- BASE DE DATOS TIPO DE CAMBIO A USD
SELECT FactorDate,FromCurrenCyCode,ToCurrencyCode,ExchangeFactor AS ExchangeFactorUSD
INTO #ExchangeUSD_BookDepDateANC
FROM PAYMENTS.dbo.tbMstExchangeFactorAllCurrencies
-- Sólo cambio a USD
WHERE ToCurrencyCode='USD'
AND FactorDate BETWEEN @startdate AND @enddate

-- BASE DE DATOS TIPO DE CAMBIO A COP
SELECT FactorDate,FromCurrenCyCode,ToCurrencyCode,ExchangeFactor AS ExchangeFactorCOP
INTO #ExchangeCOP_BookDepDateANC
FROM PAYMENTS.dbo.tbMstExchangeFactorAllCurrencies
-- Sólo cambio a COP
WHERE ToCurrencyCode='COP'

-- BASE DE DATOS PASAJEROS
SELECT RecordLocator,BookingNumber,PassengerID,LegID,BookingBookDate,AirlineCode,FlightNumber,Leg,DepartureDate,BookingClass,Origination,ConnectingAirport
INTO #PAX_BookDepDateANC
FROM EDW.dbo.PNR
LEFT JOIN #Canales_BookDepDateANC AS Canales ON PNR.SalesChannel = Canales.salesChannel
WHERE BookingBookDate BETWEEN @startdate2 AND @enddate
GROUP BY RecordLocator,BookingNumber,PassengerID,LegID,BookingBookDate,AirlineCode,FlightNumber,Leg,DepartureDate,BookingClass,Origination,ConnectingAirport

-- BASE DE DATOS ANCILLARIES
SELECT RecordLocator,BookingNumber,PassengerID,LegID,FeeCode,FeeDescription,PNRMapping,SalesChannel AS RV_SalesChannel
,FeeSalesChannel,BookingBookDate,FeeBookDate,FlightStatus,AirlineCode,FlightNumber,Journey,MarketJourney
,Leg,MarketLeg,DepartureAirport,ArrivalAirport,TypeD_I,TypeD_IJourney,DepartureDate,InitialPaymentDescription
,OwningCarrierCode,FeeBookAgent,CurrencyCode,SUM(DISTINCT FeeCountLeg) AS FeeCountLeg,SUM(DISTINCT FeeCountJourney) AS FeeCountJourney
,SUM(ISNULL(Fee,0)) AS Fee,SUM(ISNULL(FeeWaiver,0)) AS FeeWaiver,SUM(ISNULL(AncillaryRevenue,0)) AS AncillaryRevenue
INTO #ANC_BookDepDateANC_Consolidado
FROM EDW.dbo.PNRAncillary 
WHERE FeeBookDate BETWEEN @startdate AND @enddate 
-- Filtros propios de ANC
AND PNRMapping = 'Fee' 
GROUP BY RecordLocator,BookingNumber,PassengerID,LegID,FeeCode,FeeDescription,PNRMapping,SalesChannel,FeeSalesChannel,BookingBookDate,FeeBookDate
,FlightStatus,AirlineCode,FlightNumber,Journey,MarketJourney,Leg,MarketLeg,DepartureAirport
,ArrivalAirport,TypeD_I,TypeD_IJourney,DepartureDate,InitialPaymentDescription,OwningCarrierCode,FeeBookAgent,CurrencyCode

------------------------------ UNION DE TABLAS
SELECT ANC.RecordLocator,ANC.BookingNumber,ANC.PassengerID,ANC.LegID,FeeCode,FeeDescription,RV_SalesChannel
,CanalesRV.CanalVenta AS RV_CanalVenta,FeeSalesChannel,CanalesANC.CanalVenta AS ANC_CanalVenta,ANC.BookingBookDate,FeeBookDate
,FlightStatus,ANC.AirlineCode,ANC.FlightNumber,FlightTypeDescription,Origination,ConnectingAirport,Journey,MarketJourney,ANC.Leg
,MarketLeg,DepartureAirport,ArrivalAirport,BookingClass,TypeD_I,TypeD_IJourney,ANC.DepartureDate,InitialPaymentDescription
,OwningCarrierCode,FeeBookAgent,CurrencyCode,ExchangeFactorCOP,ExchangeFactorUSD,SUM(FeeCountLeg) AS FeeCountLeg
,SUM(FeeCountJourney) AS FeeCountJourney,SUM(Fee*ExchangeFactorCOP) AS FeeCOP,SUM(FeeWaiver*ExchangeFactorCOP) AS FeeWaiverCOP
,SUM(AncillaryRevenue*ExchangeFactorCOP) AS AncillaryRevenueCOP,SUM(Fee*ExchangeFactorUSD) AS FeeUSD
,SUM(FeeWaiver*ExchangeFactorUSD) AS FeeWaiverUSD,SUM(AncillaryRevenue*ExchangeFactorUSD) AS AncillaryRevenueUSD
INTO ##BookDepDate_ANC
FROM #ANC_BookDepDateANC_Consolidado AS ANC

LEFT JOIN #PAX_BookDepDateANC AS PNR ON PNR.RecordLocator = ANC.RecordLocator AND PNR.BookingNumber = ANC.BookingNumber AND PNR.PassengerID = ANC.PassengerID AND PNR.LegID = ANC.LegID
LEFT JOIN #Canales_BookDepDateANC AS CanalesANC ON ANC.FeeSalesChannel = CanalesANC.salesChannel
LEFT JOIN #Canales_BookDepDateANC AS CanalesRV ON ANC.RV_SalesChannel = CanalesRV.salesChannel
LEFT JOIN #Flights_BookDepDateANC AS Flights ON ANC.FlightNumber = Flights.FlightNumber AND ANC.AirlineCode = Flights.Carrier
LEFT JOIN #ExchangeUSD_BookDepDateANC AS ExchangeUSD ON ANC.FeeBookDate = ExchangeUSD.FactorDate AND ExchangeUSD.FromCurrenCyCode = ANC.CurrencyCode
LEFT JOIN #ExchangeCOP_BookDepDateANC AS ExchangeCOP ON ANC.FeeBookDate = ExchangeCOP.FactorDate AND ExchangeCOP.FromCurrenCyCode = ANC.CurrencyCode

WHERE FeeBookDate BETWEEN @startdate AND @enddate

GROUP BY ANC.RecordLocator,ANC.BookingNumber,ANC.PassengerID,ANC.LegID,FeeCode,FeeDescription,RV_SalesChannel
,CanalesRV.CanalVenta,FeeSalesChannel,CanalesANC.CanalVenta,ANC.BookingBookDate,FeeBookDate
,FlightStatus,ANC.AirlineCode,ANC.FlightNumber,FlightTypeDescription,Origination,ConnectingAirport,Journey,MarketJourney,ANC.Leg
,MarketLeg,DepartureAirport,ArrivalAirport,BookingClass,TypeD_I,TypeD_IJourney,ANC.DepartureDate,InitialPaymentDescription
,OwningCarrierCode,FeeBookAgent,CurrencyCode,ExchangeFactorCOP,ExchangeFactorUSD


------------------------------ PRUEBAS
DECLARE @P1 DATE = '2022-01-01';
DECLARE @P2 DATE = '2022-05-05';

SELECT MONTH(DepartureDate), SUM(FeeCountLeg) AS FeeCountLeg, SUM(AncillaryRevenueUSD) AS AncillaryRevenueUSD, SUM(AncillaryRevenueCOP) AS AncillaryRevenueCOP
FROM ##BookDepDate_ANC
WHERE FlightStatus = 'Y' AND FlightTypeDescription = 'Regular' AND AncillaryRevenueUSD > 0
AND DepartureDate BETWEEN @P1 AND @P2
AND FeeCode = 'FMAU'
GROUP BY MONTH(DepartureDate)
ORDER BY MONTH(DepartureDate)

