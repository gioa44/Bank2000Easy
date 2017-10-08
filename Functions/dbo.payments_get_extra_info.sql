SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[payments_get_extra_info](@rec_id int, @transit_accc_id int, @extra_info varchar(250))
RETURNS varchar(250)
AS
BEGIN
	RETURN @extra_info
END
GO
