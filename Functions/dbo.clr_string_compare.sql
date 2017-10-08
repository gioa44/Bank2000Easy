SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE FUNCTION [dbo].[clr_string_compare] (@strA [nvarchar] (4000), @strB [nvarchar] (4000))
RETURNS [int]
WITH EXECUTE AS CALLER
EXTERNAL NAME [AltaSoft.Sql].[AltaSoft.Sql.Utils].[StringCompare]
GO
