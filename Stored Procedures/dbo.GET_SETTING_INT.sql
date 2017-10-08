SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_SETTING_INT]
	@param_name varchar(20),
	@int_val int OUTPUT
AS

SET NOCOUNT ON;

SET @int_val = NULL

SELECT @int_val = CONVERT(int, VALS)
FROM dbo.INI_INT (NOLOCK)
WHERE IDS = @param_name

SET @int_val = ISNULL(@int_val, 0)

RETURN (0)
GO
