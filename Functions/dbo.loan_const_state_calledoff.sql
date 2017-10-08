SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_state_calledoff]()
RETURNS tinyint AS
BEGIN
	RETURN (70) -- ÂÀÌÏÈáÏÅÉËÉ
END
GO
