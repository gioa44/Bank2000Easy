SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [export].[get_bank_un_number]()
RETURNS varchar(10)
AS
BEGIN
DECLARE	
	@result varchar(10)

	SELECT 
		@result = VALS
	FROM dbo.INI_STR
	WHERE IDS = 'BANK_TAX_CODE'
	
	RETURN @result
END
GO
