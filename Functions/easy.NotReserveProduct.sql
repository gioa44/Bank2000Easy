SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [easy].[NotReserveProduct] (@ProductId int)
RETURNS bit
BEGIN
DECLARE 
	@result bit,
	@Attrib varchar(100)

SELECT 
	@Attrib = ATTRIB_VALUE
FROM dbo.LOAN_PRODUCT_ATTRIBUTES (NOLOCK)
WHERE PRODUCT_ID = @ProductId	
	
SET @result = CASE WHEN ISNULL(@Attrib, '0') = '1' THEN 1 ELSE 0 END

RETURN @result

/*
-- proc to change LOAN_SP_GET_RISK_ACCRUAL_LIST
DECLARE @NoReservedProducts TABLE (ProductId int PRIMARY KEY)

INSERT INTO @NoReservedProducts
SELECT PRODUCT_ID FROM LOAN_PRODUCTS (NOLOCK)
WHERE easy.NotReserveProduct(PRODUCT_ID) = 1

select * from @NoReservedProducts
*/
END
GO
