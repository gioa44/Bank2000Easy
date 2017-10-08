SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[ufc_get_bank_code] (@branch_id int, @dept_no int)
RETURNS int
BEGIN	
	DECLARE
		@bank_code int
	SELECT @bank_code = CODE9 FROM dbo.DEPTS
	WHERE DEPT_NO = @dept_no

	RETURN @bank_code
END
GO
