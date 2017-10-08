SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE FUNCTION [export].[get_client_code](@client_id int)  
RETURNS varchar(20) AS  
BEGIN 
DECLARE 
	@personal_id varchar(20),
	@tax_code varchar(20),
	@client_type_id int

	SELECT 
		@client_type_id = cl.CLIENT_TYPE, 
		@personal_id = cl.PERSONAL_ID, 
		@tax_code = cl.TAX_INSP_CODE
	FROM dbo.CLIENTS cl
	WHERE cl.CLIENT_NO = @client_id

	RETURN (CASE WHEN (@client_type_id = 1) THEN @personal_id ELSE @tax_code END)
END

GO
