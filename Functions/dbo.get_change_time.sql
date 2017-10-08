SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[get_change_time](@rec_id int, @parent_rec_id int, @time_date bit)
RETURNS varchar(20)
BEGIN
	DECLARE
		@dt datetime,
		@result varchar(20)
		
	SET @dt = NULL
	
	SELECT @dt = TIME_OF_CHANGE 
	FROM dbo.DOC_CHANGES_ARC (NOLOCK)
	WHERE DOC_REC_ID = @rec_id AND (LEFT(DESCRIP, 16) = 'ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ')
	
	IF @dt IS NULL
	BEGIN
		SELECT @dt = TIME_OF_CHANGE 
		FROM dbo.DOC_CHANGES_ARC (NOLOCK)
		WHERE DOC_REC_ID = @parent_rec_id AND (LEFT(DESCRIP, 16) = 'ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ')
	END
	
	--SET @result = CAST(@dt AS time(7))
	IF @time_date = 0
		SET @result = CONVERT(VARCHAR(20) , @dt, 108) 
	ELSE SET @result = CONVERT(VARCHAR(11) , convert(smalldatetime, floor(convert(money, @dt))) )
	
	RETURN @result	
END
GO
