SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE FUNCTION [dbo].[clr_ansi_to_unicode] (@value [nvarchar] (4000))
RETURNS [nvarchar] (4000)
WITH EXECUTE AS CALLER
EXTERNAL NAME [AltaSoft.Sql].[AltaSoft.Sql.Utils].[AnsiToUnicode]
GO
