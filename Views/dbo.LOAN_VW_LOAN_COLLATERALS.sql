SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE VIEW [dbo].[LOAN_VW_LOAN_COLLATERALS]
AS
SELECT 
	CONVERT(bit, NULL) AS MAIN, 
	lc.COLLATERAL_ID, lc.ROW_VERSION, lc.LOAN_ID, lc.CREDIT_LINE_ID, lc.CLIENT_NO, lc.OWNER, lc.ISO, lc.COLLATERAL_TYPE, lc.AMOUNT, CONVERT(text, lc.DESCRIP) AS DESCRIP,
	lc.MARKET_AMOUNT, lc.IS_ENSURED, lc.ENSURANCE_PAYMENT_AMOUNT, lc.ENSUR_PAYMENT_INTERVAL_TYPE,
	lc.ENSURANCE_COMPANY_ID,
	c.DESCRIP AS CLIENT_FULLNAME, c.DESCRIP_LAT AS CLIENT_FULLNAME_LAT, lct.DESCRIP AS LCT_DESCRIP, lct.DESCRIP_LAT AS LCT_DESCRIP_LAT, 
	CONVERT(varchar(max), COLLATERAL_DETAILS) AS XML_STR
FROM dbo.LOAN_COLLATERALS lc (NOLOCK)
	INNER JOIN dbo.CLIENTS c WITH (NOLOCK) ON lc.CLIENT_NO = c.CLIENT_NO
	INNER JOIN dbo.LOAN_COLLATERAL_TYPES lct WITH (NOLOCK) ON lc.COLLATERAL_TYPE=lct.TYPE_ID
GO
