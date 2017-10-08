SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[loan_const_op_payment_writedoff]()
RETURNS tinyint AS
BEGIN
	RETURN (201) -- ÜÀÌÏßÄÒÉËÉ ÓÄÓáÉÓ ÃÀ×ÀÒÅÀ
END
GO
