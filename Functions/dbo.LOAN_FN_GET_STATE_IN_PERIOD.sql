SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [dbo].[LOAN_FN_GET_STATE_IN_PERIOD](@loan_id int, @date smalldatetime)
RETURNS tinyint
AS
BEGIN
	DECLARE
		@state tinyint

	SET @state = NULL

	IF @date <> dbo.loan_open_date()
	BEGIN
		SELECT TOP 1 @state = hist.[STATE]
		FROM dbo.LOANS_HISTORY hist (NOLOCK)
			 INNER JOIN dbo.LOAN_OPS ops ON hist.OP_ID = ops.OP_ID
		WHERE hist.LOAN_ID = @loan_id AND ops.OP_DATE >= @date
		ORDER BY ops.OP_DATE ASC

		IF @state IS NULL
			SELECT TOP 1 @state = hist.[STATE]
			FROM dbo.LOANS_HISTORY hist (NOLOCK)
			WHERE hist.LOAN_ID = @loan_id
			ORDER BY hist.OP_ID DESC
	END

	IF @state IS NULL 
		SELECT @state = [STATE] FROM dbo.LOANS 
		WHERE LOAN_ID = @loan_id
		

	RETURN @state
END
GO
