SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [export].[MARK_OVERDUED_LOANS_AS_SEND] 
AS
	INSERT INTO export.LOAN_STATE 
		SELECT DISTINCT LOAN_ID, 0 
		FROM export.OVERDUED_LOANS 
		WHERE LOAN_ID NOT IN (SELECT LOAN_ID FROM export.LOAN_STATE)

	UPDATE export.LOAN_STATE
	SET SEND_STATE = 1 
	FROM 
		export.LOAN_STATE ls	
		INNER JOIN dbo.LOANS l ON ls.LOAN_ID = l.LOAN_ID AND l.STATE = dbo.loan_const_state_closed()

	--WHERE EXISTS(SELECT * FROM dbo.LOANS l WHERE l.LOAN_ID = ls.LOAN_ID AND l.CLOSE_DATE IS NOT NULL)

RETURN
GO