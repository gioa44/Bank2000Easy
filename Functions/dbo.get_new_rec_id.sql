SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[get_new_rec_id] (@branch_id int, @old_rec_id int) 
RETURNS int
AS
BEGIN
	DECLARE @rec_id int
	SET @rec_id = @old_rec_id
	IF @branch_id <> 0 
		SET @rec_id = 100000000 + @old_rec_id * 20 + @branch_id
	RETURN @rec_id
END
GO
