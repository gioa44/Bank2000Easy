SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[sys_database_id]()
RETURNS int AS
BEGIN
  RETURN (SELECT VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'DATABASE_ID')
END
GO