SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[get_new_user_id] (@branch_id int, @old_rec_id int) 
RETURNS int
AS
BEGIN
	DECLARE @rec_id int
	SET @rec_id  = @old_rec_id
	IF @rec_id  > 10
		SET @rec_id  = dbo.get_new_rec_id(@branch_id, @old_rec_id)
	RETURN @rec_id
END
GO
