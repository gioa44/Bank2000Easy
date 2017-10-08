SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_const_op_writedoff_forgive]()
RETURNS tinyint AS
BEGIN
	RETURN (165) -- ÜÀÌÏßÄÒÉËÉ ÃÀÅÀËÉÀÍÄÁÉÓ ÐÀÔÉÄÁÀ
END
GO
