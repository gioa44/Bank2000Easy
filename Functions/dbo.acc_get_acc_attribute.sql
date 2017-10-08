SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[acc_get_acc_attribute] (@acc_id int, @attrib_code varchar(50)) 
RETURNS varchar(1000)
AS
BEGIN

  RETURN (SELECT ATTRIB_VALUE FROM dbo.ACC_ATTRIBUTES (NOLOCK) WHERE ACC_ID = @acc_id AND ATTRIB_CODE = @attrib_code)
END
GO
