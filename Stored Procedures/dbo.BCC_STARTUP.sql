SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO




CREATE PROCEDURE [dbo].[BCC_STARTUP] AS

SET DATEFORMAT 'mdy'
SELECT VALS FROM INI_STR WHERE IDS='DBVER'



GO