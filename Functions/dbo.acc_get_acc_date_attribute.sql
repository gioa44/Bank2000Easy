SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[acc_get_acc_date_attribute] (@acc_id int, @attrib_code varchar(50)) 
RETURNS datetime
AS
BEGIN

  RETURN (SELECT CONVERT(datetime, ATTRIB_VALUE, 103) FROM dbo.ACC_ATTRIBUTES (NOLOCK) WHERE ACC_ID = @acc_id AND ATTRIB_CODE = @attrib_code)
END
GO
