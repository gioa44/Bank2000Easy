SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_calloff]()
RETURNS tinyint AS
BEGIN
	RETURN (90) -- ÓÄÓáÉÓ ÂÀÌÏÈáÏÅÀ
END
GO
