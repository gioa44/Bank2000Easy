SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_get_prev_op_id] (@did int, @oid int)
RETURNS INT
AS
BEGIN
  DECLARE @prev_oid int

  IF @oid = -1
    SELECT @prev_oid = (SELECT MAX(OP_ID) FROM dbo.DEPO_OPS WHERE DEPO_ID = @did)
  ELSE
    SELECT @prev_oid = (SELECT MAX(OP_ID) FROM dbo.DEPO_OPS WHERE DEPO_ID = @did AND OP_ID < @oid)

	RETURN @prev_oid
END
GO
