SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE FUNCTION [dbo].[clr_add_new_param_to_procedure] (@procedureText [nvarchar] (4000), @paramStr [nvarchar] (4000), @index [int])
RETURNS [nvarchar] (4000)
WITH EXECUTE AS CALLER
EXTERNAL NAME [AltaSoft.Sql].[AltaSoft.Sql.Utils].[AddNewParamToProcedure]
GO
