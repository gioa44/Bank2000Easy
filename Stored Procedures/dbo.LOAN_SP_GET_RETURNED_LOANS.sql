SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_RETURNED_LOANS]
AS

DECLARE 
	@loan_open_date smalldatetime
 
SET @loan_open_date = dbo.loan_open_date()

SELECT LVL.*
FROM dbo.LOAN_VW_LOANS LVL
	INNER JOIN dbo.LOAN_DETAILS LD ON LD.LOAN_ID = LVL.LOAN_ID
WHERE (LD.CALC_DATE <> @loan_open_date)

RETURN
GO
