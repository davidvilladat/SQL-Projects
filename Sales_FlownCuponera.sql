DECLARE @date Date = '2021-01-01';


WITH 

--This table bring us the redeemed coupons

Redimidos AS(
SELECT VoucherID,Type_D_I_Voucher,Recordlocator_Redimido,RecordLocator,LegCount,CAST(CreatedDate AS DATE) AS CreatedDateUTC,CAST(Expiration AS DATE) AS Expiration,
CAST(RedemptionDate AS DATE) AS RedemptionDate
FROM Voucher.dbo.tbRedencionCuponeras_CustomerServices

),

--Exchange factor

Exchange AS (
    SELECT FactorDate,FromCurrenCyCode,ToCurrencyCode,ExchangeFactor
    FROM PAYMENTS.dbo.tbMstExchangeFactorAllCurrencies
    -- Currency change only USD & COP between the dates
    WHERE FactorDate>=@date AND FactorDate<=CAST(GETDATE()-1 AS DATE)  AND ((FromCurrencyCode = 'USD' AND ToCurrencyCode = 'COP') OR (FromCurrencyCode = 'COP' AND ToCurrencyCode = 'USD'))),


--Trae las cuponeras vendidas por dia de compra, tipo de cuponera e ingreso neto asociado
CuponeraEDW AS (
SELECT RecordLocator,PaymentStatus,CAST(BookingBookDateLocal AS DATE) AS PurchaseDate,FeeCode, FeeWaiver, CurrencyCode,

        CASE 
            WHEN CurrencyCode='COP' then FeeWaiver 
            ELSE  E.ExchangeFactor*FeeWaiver
        END  COPSales,

        CASE 
            WHEN CurrencyCode='USD' then FeeWaiver 
            ELSE  E.ExchangeFactor*FeeWaiver
        END  USDSales,

        CASE 
            WHEN FeeCode IN ('FCDC5', 'FCDC8') THEN 'DOMCO'
            WHEN FeeCode IN ('PPDP8', 'PPDP5') THEN 'DOMPE'
            WHEN FeeCode IN ('PIDP3', 'PPIP5','FCIC3','FCIC5','FPIC8') THEN 'INT'
            ELSE 'Error'
        END AS Market
FROM EDW.dbo.tbCuponera LEFT JOIN Exchange AS E ON CAST(BookingBookDateLocal AS DATE)=E.FactorDate AND E.FromCurrenCyCode=CurrencyCode 
WHERE PaymentStatus = 'Approved'),

--Ahora seleccionemos PNR para filtrar status de vuelo y fechas de Booking y FLOWN 

PNR AS (
    SELECT RecordLocator,BookingBookDate,DepartureDate,BookingClass,Leg,SalesChannel
    FROM EDW.dbo.PNR AS PNR
    WHERE FlightStatus = 'Y' AND BookingBookDate>=@date AND BookingBookDate<=CAST(GETDATE()-1 AS DATE))


SELECT PurchaseDate,VoucherID,Type_D_I_Voucher,C.RecordLocator AS Cuponera,R.Recordlocator_Redimido AS Coupon,LegCount,CreatedDateUTC,Expiration, 
RedemptionDate,DepartureDate,C.FeeCode,CurrencyCode,BookingClass,Leg,SalesChannel,Market,COPSales,USDSales,
        CASE 
                WHEN Market = 'DOMCO' THEN (1-0.26)*SUM(COPSales)
                WHEN Market = 'DOMPE' THEN (1-0.39)*SUM(COPSales)
                WHEN Market = 'INT' THEN (1-0.54)*SUM(COPSales)
                ELSE 0
            END AS COPSalesWithoutTaxes,


            CASE 
                WHEN Market = 'DOMCO' THEN (1-0.26)*SUM(USDSales)
                WHEN Market = 'DOMPE' THEN (1-0.39)*SUM(USDSales)
                WHEN Market = 'INT' THEN (1-0.54)*SUM(USDSales)
                ELSE 0
            END AS USDSalesWithoutTaxes

FROM Redimidos R LEFT JOIN CuponeraEDW C ON R.Recordlocator = C.RecordLocator LEFT JOIN PNR ON R.Recordlocator_Redimido = PNR.RecordLocator 


GROUP BY PurchaseDate,C.RecordLocator, R.Recordlocator_Redimido, VoucherID, Type_D_I_Voucher,CreatedDateUTC,Expiration, 
RedemptionDate,C.FeeCode, FeeWaiver, CurrencyCode,DepartureDate,BookingClass,Leg,LegCount,SalesChannel,Market,COPSales,USDSales  

ORDER BY PurchaseDate DESC, DepartureDate DESC 