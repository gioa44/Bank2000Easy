SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO







--------------------------------------------------

CREATE FUNCTION [dbo].[CHANGE_TEXT]( @TMP_STR VARCHAR(100), @TMP_SUB_STR VARCHAR(100))
RETURNS VARCHAR(100)
AS
BEGIN

RETURN SUBSTRING(@TMP_STR, CHARINDEX(@TMP_SUB_STR, @TMP_STR) + LEN(@TMP_SUB_STR), 999)

END

GO
