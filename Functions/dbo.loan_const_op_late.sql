SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_late]()
RETURNS tinyint AS
BEGIN
	RETURN (70) -- ÓÄÓáÉÓ ÃÀÂÅÉÀÍÄÁÀ
END
GO
