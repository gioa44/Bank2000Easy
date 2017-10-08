SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE FUNCTION [dbo].[DX_FN_GET_BANK_ADDRESS_FACT](@dept_no int)
RETURNS varchar(1000)
AS
BEGIN
	DECLARE
		@result varchar(1000)
	
	SET @result = ''
	SELECT @result=ADDRESS FROM dbo.DEPTS (NOLOCK) WHERE DEPT_NO=@dept_no	
	SET @result = CASE WHEN ISNULL(@result, '')='' THEN 'N/A' ELSE @result END

	RETURN (@result)
END
GO