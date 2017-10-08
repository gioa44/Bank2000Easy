SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[ops_get_ops_date_attribute] (@op_id int, @attrib_code varchar(50)) 
RETURNS datetime
AS
BEGIN

  RETURN (SELECT CONVERT(datetime, ATTRIB_VALUE, 103) FROM dbo.DOC_ATTRIBUTES (NOLOCK) WHERE REC_ID = @op_id AND ATTRIB_CODE = @attrib_code)
END
GO
