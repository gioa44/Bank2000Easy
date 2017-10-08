SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [impexp].[get_portion_in_swift_on_user](@iso char(3), @cor_bank_id int)
RETURNS int AS
BEGIN
	DECLARE 
		@portion int
	
	SET @portion = 0

	RETURN @portion 	
END
GO
