SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_state_writedoff]()
RETURNS tinyint AS
BEGIN
	RETURN (100) -- ÜÀÌÏßÄÒÉËÉ
END
GO
