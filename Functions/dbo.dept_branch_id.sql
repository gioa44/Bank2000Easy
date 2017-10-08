SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------

CREATE FUNCTION [dbo].[dept_branch_id](@dept_no int)
RETURNS int
AS
BEGIN
	DECLARE @branch_id int
	
	SELECT @branch_id = BRANCH_ID
	FROM dbo.DEPTS (NOLOCK)
	WHERE DEPT_NO = @dept_no

	RETURN @branch_id 
END
GO
