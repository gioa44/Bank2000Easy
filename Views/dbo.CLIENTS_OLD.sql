SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CLIENTS_OLD] AS

SELECT C.*, 
	dbo.cli_get_cli_attribute (C.CLIENT_NO, '$ADDRESS_FACT') AS ADDRESS_FACT,
	dbo.cli_get_cli_attribute (C.CLIENT_NO, '$ADDRESS_LAT') AS ADDRESS_LAT,
	dbo.cli_get_cli_attribute (C.CLIENT_NO, '$ADDRESS_LEGAL') AS ADDRESS_JUR,
	dbo.cli_get_cli_attribute (C.CLIENT_NO, 'FAX') AS FAX,
	dbo.cli_get_cli_attribute (C.CLIENT_NO, '$EMAIL') AS E_MAIL,
	dbo.cli_get_cli_attribute (C.CLIENT_NO, 'CHILD_COUNT') AS CHILDREN_COUNT
FROM dbo.CLIENTS C
GO
