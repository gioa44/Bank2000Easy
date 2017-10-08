SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_is_all_ops_commited] (@did int)
RETURNS bit
AS
BEGIN
  DECLARE @commited bit

  SET @commited = CASE WHEN (EXISTS (SELECT * FROM dbo.DEPO_OPS WHERE DEPO_ID = @did AND COMMIT_STATE <> 0xFF)) THEN 0 ELSE 1 END

  RETURN @commited
END
GO
