SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_GET_PRODUCTS_LIST]
	@user_id int,
	@all_products bit,
	@client_no int,
	@is_credit_line bit
AS
SET NOCOUNT ON

DECLARE
	@client_type int,
	@client_subtype int,
	@is_insider bit,
	@is_resident bit,
	@is_employee bit

SELECT @client_type = CLIENT_TYPE, @client_subtype = ISNULL(CLIENT_SUBTYPE, 0), @is_insider = IS_INSIDER, @is_insider = IS_INSIDER, @is_employee = IS_EMPLOYEE
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no

IF @client_type = 1
	SET @client_subtype = 0
IF @client_type = 2
	SET @client_subtype = POWER(2, @client_subtype - 1)
IF @client_type = 3
    SET @client_subtype = POWER(2, @client_subtype + 1)
IF @client_type = 4
	SET @client_subtype = POWER(2, @client_subtype + 8)

IF @all_products = 1
	SELECT * 
	FROM dbo.LOAN_PRODUCTS (NOLOCK)
	WHERE (IS_ACTIVE=1) AND (CLIENT_TYPES & POWER(2, @client_type - 1) <> 0) AND
	(@client_subtype = 0 OR CLIENT_SUBTYPES & @client_subtype <> 0) AND 
	(@is_credit_line = 0 OR @is_credit_line = 1 AND CREDIT_LINE = 1) AND (
	((@is_insider = 1 AND CLIENT_PROPERTIES & 1 <> 0) OR (@is_insider = 0 AND CLIENT_PROPERTIES & 2 <> 0))  OR
	((@is_resident = 1 AND CLIENT_PROPERTIES & 4 <> 0) OR (@is_resident = 0 AND CLIENT_PROPERTIES & 8 <> 0)) OR
	((@is_employee = 1 AND CLIENT_PROPERTIES & 16 <> 0) OR (@is_employee = 0 AND CLIENT_PROPERTIES & 32 <> 0))
	)
ELSE
	SELECT P.*
	FROM dbo.LOAN_PRODUCTS P (NOLOCK)
		INNER JOIN dbo.LOAN_PRODUCT_USERS U (NOLOCK) ON P.PRODUCT_ID = U.PRODUCT_ID
	WHERE (U.USER_ID = @user_id) AND (P.IS_ACTIVE=1) AND (P.CLIENT_TYPES & POWER(2, @client_type - 1) <> 0) AND
	(@client_subtype = 0 OR P.CLIENT_SUBTYPES & @client_subtype <> 0) AND
	(@is_credit_line = 0 OR @is_credit_line = 1 AND CREDIT_LINE = 1) AND (
	((@is_insider = 1 AND P.CLIENT_PROPERTIES & 1 <> 0) OR (@is_insider = 0 AND P.CLIENT_PROPERTIES & 2 <> 0))  OR
	((@is_resident = 1 AND P.CLIENT_PROPERTIES & 4 <> 0) OR (@is_resident = 0 AND P.CLIENT_PROPERTIES & 8 <> 0)) OR
	((@is_employee = 1 AND P.CLIENT_PROPERTIES & 16 <> 0) OR (@is_employee = 0 AND P.CLIENT_PROPERTIES & 32 <> 0))
	)
RETURN 0
GO
