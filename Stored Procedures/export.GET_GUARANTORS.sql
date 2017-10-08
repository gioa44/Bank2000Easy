SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [export].[GET_GUARANTORS]
	@loan_id int
AS
	SELECT 
		col.CLIENT_NO AS OWNER_CLIENT_ID,
		export.get_client_type3(col.CLIENT_NO) AS CLIENT_TYPE,
		export.get_bank_un_number() AS BANK_UN_NUMBER,
		loan.AGREEMENT_NO,
		export.get_client_code(col.CLIENT_NO) AS [IDENTITY]
	FROM dbo.LOANS loan
		LEFT JOIN dbo.LOAN_COLLATERALS col ON loan.LOAN_ID = col.LOAN_ID OR loan.CREDIT_LINE_ID = col.CREDIT_LINE_ID
		LEFT JOIN dbo.CLIENTS cl ON col.CLIENT_NO = cl.CLIENT_NO
	WHERE loan.LOAN_ID = @loan_id AND col.COLLATERAL_TYPE = 6 -- ÌÄÓÀÌÄ ÐÉÒÉÓ ÂÀÒÀÍÔÉÀ
GO
