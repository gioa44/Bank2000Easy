SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [impexp].[get_state_name] (@state int, @lat bit = 0)
RETURNS varchar(50)
AS
BEGIN
	DECLARE @state_name varchar(50)

	SELECT @state_name = NAME_GEO
	FROM impexp.PORTION_STATES (NOLOCK)
	WHERE STATE = @state

	RETURN @state_name
END
GO
