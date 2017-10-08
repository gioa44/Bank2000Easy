SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_penalty_stop]()
RETURNS tinyint AS
BEGIN
	RETURN (150) -- ÓÄÓáÆÄ ãÀÒÉÌÉÓ ÛÄÜÄÒÄÁÀ
END
GO
