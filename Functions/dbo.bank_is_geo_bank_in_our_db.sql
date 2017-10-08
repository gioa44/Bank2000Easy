SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[bank_is_geo_bank_in_our_db] (@bank_code TGEOBANKCODE)
RETURNS bit AS
BEGIN
	DECLARE @b bit
	IF EXISTS(SELECT TOP 1 * FROM dbo.DEPTS (NOLOCK) WHERE CODE9 = @bank_code AND DATABASE_ID = dbo.sys_database_id())
		SET @b = 1
	ELSE
		SET @b = 0
	RETURN @b
END
GO
