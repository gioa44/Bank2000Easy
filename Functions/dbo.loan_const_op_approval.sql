SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_approval]()
RETURNS tinyint AS
BEGIN
	RETURN (40) -- ÓÄÓáÉÓ ÃÀÌÔÊÉÝÄÁÀ
END
GO
