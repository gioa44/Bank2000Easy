SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_penalty_restore]()
RETURNS tinyint AS
BEGIN
	RETURN (155) -- ÓÄÓáÆÄ ãÀÒÉÌÉÓ ÀÙÃÂÄÍÀ
END
GO
