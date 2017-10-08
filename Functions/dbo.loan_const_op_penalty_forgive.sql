SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_penalty_forgive]()
RETURNS tinyint AS
BEGIN
	RETURN (160) -- ÓÄÓáÆÄ ãÀÒÉÌÉÓ ÐÀÔÉÄÁÀ
END
GO
