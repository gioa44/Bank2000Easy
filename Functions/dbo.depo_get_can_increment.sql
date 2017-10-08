SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_get_can_increment] (@did int)
RETURNS int
AS
BEGIN
	DECLARE @can int, @st int, @oid int
  
	SET @can = 0
	SELECT @st = D.REC_STATE, @oid = D.OP_ID
	FROM dbo.DEPOS DX 
		INNER JOIN dbo.DEPO_DATA D ON DX.OP_ID = D.OP_ID
	WHERE DX.DEPO_ID = @did

	SET @can = CASE WHEN @st & 1 = 0 THEN 1 WHEN @st & 0xF000 = 0xF000 THEN 0xF000
       WHEN (SELECT ACCUMULATE FROM dbo.DEPO_DATA WHERE OP_ID = @oid) = 0 THEN 2
       ELSE 0 END
  
	RETURN @can
END
GO
