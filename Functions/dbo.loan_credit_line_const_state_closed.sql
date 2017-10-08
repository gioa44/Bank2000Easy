SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_credit_line_const_state_closed]()
RETURNS tinyint AS
BEGIN
	RETURN (255) -- ÃÀáÖÒÖËÉ
END
GO
