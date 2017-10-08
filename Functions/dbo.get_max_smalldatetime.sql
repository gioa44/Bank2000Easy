SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[get_max_smalldatetime]()
	RETURNS smalldatetime AS
BEGIN
	RETURN convert(smalldatetime, 65379) --In Delphi is 65381
END
GO
