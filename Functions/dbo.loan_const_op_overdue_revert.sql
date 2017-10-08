SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_overdue_revert]()
RETURNS tinyint AS
BEGIN
	RETURN (85) -- ÅÀÃÀÂÀÃÀÝÉËÄÁÖËÉ ÓÄÓáÉÓ ÒÄÊËÀÓÉ×ÉÊÀÝÉÀ ÒÏÂÏÒÝ ÜÅÄÖËÄÁÒÉÅÉÓÀ
END
GO
