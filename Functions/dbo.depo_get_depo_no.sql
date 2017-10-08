SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_get_depo_no] (@did int)
RETURNS varchar(50)
AS
BEGIN
  DECLARE @agr_no varchar(50)
  SET @agr_no = convert(varchar(50), @did)

  RETURN @agr_no
END
GO
