SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [export].[GET_COLLATERALS]
	@loan_id int
AS
SELECT 
		col.CLIENT_NO AS OWNER_CLIENT_ID,
		export.get_client_type3(col.CLIENT_NO) AS CLIENT_TYPE,
		export.get_bank_un_number() AS BANK_UN_NUMBER,
		loan.AGREEMENT_NO,
		ct.CODE,
		export.get_client_code(col.CLIENT_NO) AS [OWNER],
		NULL AS [ADDRESS],
		'N/A' CITY,
		'N/A' ZIP_CODE,
		'GE' AS COUNTRY,
		col.AMOUNT AS LIQUIDATION_VALUE
	FROM dbo.LOANS loan
		LEFT JOIN dbo.LOAN_COLLATERALS col ON loan.LOAN_ID = col.LOAN_ID OR loan.CREDIT_LINE_ID = col.CREDIT_LINE_ID
		LEFT JOIN dbo.CLIENTS cl ON col.CLIENT_NO = cl.CLIENT_NO
		LEFT JOIN dbo.LOAN_COLLATERAL_TYPES ct ON col.COLLATERAL_TYPE = ct.[TYPE_ID]
	WHERE loan.LOAN_ID = @loan_id AND col.COLLATERAL_TYPE <> 6 -- ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
GO