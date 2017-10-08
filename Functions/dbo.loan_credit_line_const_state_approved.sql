SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_credit_line_const_state_approved]()
RETURNS tinyint AS
BEGIN
	RETURN (30) -- ÃÀÌÔÊÉÝÄÁÖËÉ
END
GO
