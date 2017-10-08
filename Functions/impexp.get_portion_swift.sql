SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [impexp].[get_portion_swift](@doc_rec_id int)
RETURNS int AS
BEGIN
	DECLARE 
		@portion int
	
	SET @portion = impexp.get_portion_swift_on_user(@doc_rec_id)

	RETURN @portion 	
END
GO
