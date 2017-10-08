SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[DX_FN_GET_PROLONGATION](@prolongation bit)
RETURNS varchar(2000)
AS
BEGIN
	DECLARE
		@result varchar(2000)
	
	SET @result = ''
	IF @prolongation = 1 
		SET @result = 
			'golovko golovko golovko golovko golovko golovko golovko' + CHAR(13) +
			'golovko golovko golovko golovko golovko golovko golovko' + CHAR(13) +
			'golovko golovko golovko golovko golovko golovko golovko' + CHAR(13) +	
			'golovko golovko golovko golovko golovko golovko golovko' + CHAR(13)
		
	RETURN (@result)
END
GO
