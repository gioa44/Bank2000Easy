SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[classif_get_descrip](@classif_type varchar(20), @id varchar(20))
RETURNS varchar(max) AS
BEGIN
	DECLARE
		@descrip varchar(max),
		@id2 varchar(20)
	SET @descrip = ''
	SET @id2 = ''

	IF UPPER(@classif_type) = 'LOAN'
	BEGIN
		WHILE LEN(@id) > 0
		BEGIN
			SET @id2 = @id2 + SUBSTRING(@id, 1, 2)
			SELECT @descrip = @descrip + DESCRIP + '/'
			FROM dbo.LOAN_CLASSIFS (NOLOCK)
			WHERE [ID] = @id2

			SET @id = SUBSTRING(@id, 3, LEN(@id))
		END
	END

	RETURN SUBSTRING(@descrip, 1, LEN(@descrip) - 1)
END
GO
