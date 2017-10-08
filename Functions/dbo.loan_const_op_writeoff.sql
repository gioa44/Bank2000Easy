SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_writeoff]()
RETURNS tinyint AS
BEGIN
	RETURN (100) -- ÓÄÓáÉÓ ÜÀÌÏßÄÒÀ
END
GO
