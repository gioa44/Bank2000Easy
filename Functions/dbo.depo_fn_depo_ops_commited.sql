SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_depo_ops_commited] (@depo_id int)
RETURNS bit
AS
BEGIN
	DECLARE
		@commited bit

	IF NOT EXISTS (SELECT * FROM dbo.DEPO_OP WHERE DEPO_ID = @depo_id)
		SET @commited = 1
	ELSE
		SET @commited = CASE WHEN (EXISTS (SELECT * FROM dbo.DEPO_OP WHERE DEPO_ID = @depo_id AND OP_STATE <> 1)) THEN 0 ELSE 1 END

	RETURN @commited
END
GO
