SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[LOAN_SP_GET_LOAN_TO_OPEN_DAY]
	@agreement_no varchar(100),
	@loan_id int = NULL
AS

DECLARE	
	@calc_date smalldatetime,
	@state int

	SELECT 
		@loan_id = LOAN_ID, 
		@agreement_no = AGREEMENT_NO, 
		@state = [STATE]
	FROM dbo.LOANS (NOLOCK)
	WHERE (@agreement_no IS NULL OR AGREEMENT_NO = @agreement_no) AND 
		  (@loan_id IS NULL OR LOAN_ID = @loan_id)

	IF @state < dbo.loan_const_state_closed()
	BEGIN
		SELECT 
			@calc_date = CALC_DATE 
		FROM dbo.LOAN_DETAILS (NOLOCK)
		WHERE LOAN_ID = @loan_id
	END
	ELSE
	BEGIN
		SELECT TOP 1 
			@calc_date = CASE WHEN CALC_DATE IS NULL THEN CALC_DATE ELSE CALC_DATE + 1 END
		FROM dbo.LOAN_DETAILS_HISTORY (NOLOCK)
		WHERE LOAN_ID = @loan_id
		ORDER BY CALC_DATE DESC
	END

	SELECT 
		@loan_id AS LOAN_ID, 
		@agreement_no AS AGREEMENT_NO,
		@calc_date AS OPEN_DAY

GO
