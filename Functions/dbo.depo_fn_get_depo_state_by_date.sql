SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_depo_state_by_date](@depo_id int, @date smalldatetime)
RETURNS tinyint
AS
BEGIN
	DECLARE
		@state tinyint

	SET @state = NULL

	SELECT @state = [STATE] FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id AND (ISNULL(END_DATE, @date) < @date OR ISNULL(ANNULMENT_DATE, @date) < @date)

	IF @state IS NULL 	
		SELECT TOP 1 @state = h.[STATE]
		FROM dbo.DEPO_DEPOSITS_HISTORY h (NOLOCK)
			 INNER JOIN dbo.DEPO_OP o (NOLOCK) ON h.OP_ID = o.OP_ID
		WHERE h.DEPO_ID = @depo_id AND o.OP_DATE >= @date
		ORDER BY o.OP_DATE ASC


	IF @state IS NULL 
		SELECT @state = [STATE] FROM dbo.DEPO_DEPOSITS
		WHERE DEPO_ID = @depo_id AND [START_DATE] >= @date
		

	RETURN @state
END
GO
