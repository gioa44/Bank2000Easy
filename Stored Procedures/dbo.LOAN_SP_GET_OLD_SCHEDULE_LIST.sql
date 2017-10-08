SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_OLD_SCHEDULE_LIST]
  @loan_id int
AS

SET NOCOUNT ON

	SELECT	o.OP_ID, 
			s.LOAN_ID, 
			SUM(PRINCIPAL) AS LOAN_AMOUNT, 
			SUM(PRINCIPAL + INTEREST) AS WHOLE_AMOUNT, 
			o.OP_DATE, 
			ot.DESCRIP,
			ot.DESCRIP_LAT,
			o.OP_NOTE
	FROM dbo.LOAN_SCHEDULE_HISTORY s
		JOIN dbo.LOAN_OPS o ON o.OP_ID = s.OP_ID
		JOIN dbo.LOAN_OP_TYPES ot ON o.OP_TYPE = ot.TYPE_ID
	WHERE (s.LOAN_ID = @loan_id) --AND NOT o.OP_ID IN (SELECT OP_ID FROM dbo.LOAN_VW_LOAN_OP_PAYMENT WHERE LOAN_ID = @loan_id)
	GROUP BY s.LOAN_ID, o.OP_ID, o.OP_DATE, o.OP_NOTE, ot.DESCRIP, ot.DESCRIP_LAT

RETURN 
GO