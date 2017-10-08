SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_auto_prolongation_on_user](@depo_id int)
RETURNS bit AS
BEGIN
	DECLARE
		@auto_prolongation bit
		
	SET @auto_prolongation = 0
	
	DECLARE
		@prolongation_count int
	
	SELECT @prolongation_count = ISNULL(PROLONGATION_COUNT, 0)
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id
	
	IF @prolongation_count < 1
		SET @auto_prolongation = 1;
		
	RETURN (@auto_prolongation)
END
GO
