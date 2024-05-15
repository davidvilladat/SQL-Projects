SELECT 



Issue_Date,
Dep_Date,
EXTRACT(YEAR FROM Issue_Date) AS Year,
EXTRACT(MONTH FROM Issue_Date) AS Month,
EXTRACT(WEEK FROM Issue_Date) AS Week,


EXTRACT(YEAR FROM Dep_Date) AS Year_Dep,
EXTRACT(MONTH FROM Dep_Date) AS Month_Dep,
EXTRACT(WEEK FROM Dep_Date) AS Week_Dep,

--CASE
--  WHEN DATE_DIFF(DATE_TRUNC(Dep_Date, DAY), Issue_Date, DAY) < 0 THEN 0
--  WHEN DATE_DIFF(DATE_TRUNC(Dep_Date, DAY), Issue_Date, DAY) > 180 THEN 180
--  ELSE DATE_DIFF(DATE_TRUNC(Dep_Date, DAY), Issue_Date, DAY)
--END AS AP,

CASE


WHEN DATE_DIFF(DATE_TRUNC(LAST_DAY(Dep_Date),DAY),Issue_Date,DAY) < 0 THEN 0
WHEN DATE_DIFF(DATE_TRUNC(LAST_DAY(Dep_Date),DAY),Issue_Date,DAY) > 180 THEN 180
ELSE DATE_DIFF(DATE_TRUNC(LAST_DAY(Dep_Date),DAY),Issue_Date,DAY)
END AS AP,



CASE
  WHEN Segment_Origin_Country = 'AO' AND Segment_Dest_Country = 'AO' THEN 'DOMESTIC'
  WHEN Segment_Origin_Country IN('ES','PT','BR','CU') OR Segment_Dest_Country IN('ES','PT','BR','CU') THEN 'INTERCONTINENTAL'
  ELSE 'REGIONAL'
END AS Market_Type,

CASE
    WHEN LEFT(CONCAT(Segment_Origin,Segment_Dest),3) > LEFT(Segment_Dest,3) THEN CONCAT(Segment_Dest, '-', Segment_Origin)
    ELSE CONCAT(Segment_Origin,'-',Segment_Dest)
END AS Market_Leg,


LEFT(Routing,7) AS OD,
LEFT(Routing,3) AS Origin,
RIGHT(LEFT(Routing,7),3) AS Dest,
Routing,


CASE

	WHEN LEFT(Routing,3) > RIGHT(LEFT(Routing,7),3) THEN CONCAT(RIGHT(LEFT(Routing,7),3),'-',LEFT(Routing,3))
	ELSE CONCAT(LEFT(Routing,3),'-',RIGHT(LEFT(Routing,7),3))
END AS Market_Journey,





CONCAT(Segment_Origin,"-",Segment_Dest) AS Leg,

CASE

WHEN RIGHT(Routing,7) <> Routing THEN "RT" ELSE "OW"
END TypeOfTrip,

CASE 

  WHEN RBD IN ('I','O','A') THEN 'Promo'
  ELSE 'Structural'

END AS Pax_Type,



CASE

WHEN LEFT(Routing,7) IN (
    'LAD-LIS',
    'LAD-GRU',
    'LAD-CPT',
    'LAD-JNB',
    'LAD-MAD',
    'LAD-MPM',
    'LAD-HAV',
    'LAD-WDH',
    'LAD-CAB',
    'LAD-LOS',
    'CAB-LAD',
    'LAD-CBT',
    'CBT-LAD',
    'LAD-DUE',
    'DUE-LAD',
    'LAD-TMS',
    'LAD-LUO',
    'LAD-OPO',
    'LAD-FIH',
    'LUO-LAD',
    'LAD-MSZ',
    'MSZ-LAD',
    'LAD-ACC',
    'LAD-NOV',
    'LAD-PNR',
    'NOV-LAD',
    'LAD-SDD',
    'LIS-LAD',
    'GRU-LAD',
    'CPT-LAD',
    'JNB-LAD',
    'MAD-LAD',
    'MPM-LAD',
    'HAV-LAD',
    'WDH-LAD',
    'SDD-LAD',
    'LOS-LAD',
    'LAD-SPP',
    'SPP-LAD',
    'LAD-SVP',
    'SVP-LAD',
    'LAD-SZA',
    'TMS-LAD',
    'SZA-LAD',
    'OPO-LAD',
    'FIH-LAD',
    'LAD-UGO',
    'UGO-LAD',
    'LAD-VHC',
    'ACC-LAD',
    'VHC-LAD',
    'PNR-LAD',
    'LAD-VPE',
    'VPE-LAD'
)

THEN "Direct"
ELSE "Connection"
END Connection,




Channel,
Agency_Group,
Agent_Name,
Sale_Country,
Sales_Region,
Sales_Upto,
Cabin,
Coupon_Status,
Operating_Carrier,
Marketing_Carrier,
Codeshare_Type,
OTA_Group,
RBD,
Farebasis_Code,
Tour_Code,

SUM(Segment_Pax) AS PAX,
COUNT(DISTINCT(Ticket_No)) AS Ticket_PAX,
SUM(Gross_Revenue) AS Revenue,
SUM(Revenue_YQYR) AS YQYR,
SUM(Commission) AS Commission,
SUM(Discount) AS Discount,
--SUM(Gross_Revenue + Revenue_YQYR)/SUM(Segment_Pax) AS AvgFare


FROM `dt118-com.Data.DT_Sold_Segments` 

WHERE Issue_Date >= '2019-01-01'  --AND Coupon_Status IN ('F','O')  
AND Document_Type IN ('TICKET','EMDS') --AND Operating_Carrier = 'DT' 
--AND Channel = 'BSP'


GROUP BY Issue_Date,Dep_Date,Market_Type,OD,Routing,Segment_Origin,Segment_Dest,Origin,Dest,Leg,TypeOfTrip,Pax_Type,Channel,Agency_Group,Agent_Name,Sale_Country,Sales_Region,Sales_Upto,Cabin,Coupon_Status,RBD,Farebasis_Code,Tour_Code,
Operating_Carrier,Marketing_Carrier,Codeshare_Type,OTA_Group
ORDER BY Issue_Date DESC 
