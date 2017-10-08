SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_get_last_prev_op_id] (@did int)
RETURNS int
AS
BEGIN
  DECLARE @oid int
  SELECT @oid = MAX(OP_ID) FROM dbo.DEPO_OPS (NOLOCK) WHERE DEPO_ID = @did AND OP_ID < dbo.depo_get_last_op_id(@did)
  RETURN @oid
END
GO
