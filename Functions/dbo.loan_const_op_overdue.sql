SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_overdue]()
RETURNS tinyint AS
BEGIN
	RETURN (80) -- ÓÄÓáÉÓ ÅÀÃÀÂÀÃÀÝÉËÄÁÀ
END
GO
