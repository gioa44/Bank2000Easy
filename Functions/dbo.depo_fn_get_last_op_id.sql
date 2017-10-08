SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_last_op_id](@depo_id int)
RETURNS int
AS
BEGIN
	DECLARE
		@last_op_id int

	SELECT @last_op_id = MAX(OP_ID)
	FROM dbo.DEPO_OP (NOLOCK)
	WHERE DEPO_ID = @depo_id

	RETURN @last_op_id
END
GO
