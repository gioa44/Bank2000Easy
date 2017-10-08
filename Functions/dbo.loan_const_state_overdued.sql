SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_state_overdued]()
RETURNS tinyint AS
BEGIN
	RETURN (60) -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ
END
GO
