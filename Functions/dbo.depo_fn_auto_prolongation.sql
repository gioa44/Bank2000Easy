SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[depo_fn_auto_prolongation](@depo_id int)
RETURNS bit AS
BEGIN
	DECLARE
		@auto_prolongation bit
		
	SET @auto_prolongation = dbo.depo_fn_auto_prolongation_on_user(@depo_id)
	
	RETURN (@auto_prolongation)
END
GO
