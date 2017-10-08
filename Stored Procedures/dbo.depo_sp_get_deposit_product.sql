SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_deposit_product]
	@client_type int,
	@client_property int,
	@birth_date smalldatetime,
	@sys_bank_date smalldatetime,
	@user_id int
AS
BEGIN
	SET NOCOUNT ON

	DECLARE
		@child_deposit bit

	IF @client_type = 32
	BEGIN
		IF DATEADD(year, 18, @birth_date) > @sys_bank_date
			SET @child_deposit = 1
		ELSE
			SET @child_deposit = 0
	END
	ELSE
		SET @child_deposit = 0

	SELECT CONVERT(varchar(50), REPLICATE(0, 4 - LEN(convert(varchar(4), PROD_NO))) + convert(varchar(4),PROD_NO)) + ' - ' + CODE + ' - ' + DESCRIP AS PROD_DESCRIP, *
	FROM dbo.DEPO_PRODUCT (NOLOCK)
	WHERE IS_ACTIVE = 1 AND CHILD_DEPOSIT = @child_deposit AND CLIENT_TYPES & @client_type <> 0 AND CLIENT_PROPERTIES & @client_property <> 0

RETURN
END
GO
