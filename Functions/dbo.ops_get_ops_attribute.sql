SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [dbo].[ops_get_ops_attribute] (@op_id int, @attrib_code varchar(50)) 
RETURNS varchar(1000)
AS
BEGIN

  RETURN (SELECT ATTRIB_VALUE FROM dbo.DOC_ATTRIBUTES (NOLOCK) WHERE REC_ID = @op_id AND ATTRIB_CODE = @attrib_code)
END
GO
