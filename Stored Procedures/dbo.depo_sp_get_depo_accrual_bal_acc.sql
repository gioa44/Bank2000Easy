SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_accrual_bal_acc]
	@bal_acc TBAL_ACC OUTPUT,
	@depo_bal_acc TBAL_ACC,
	@client_no int,
	@prod_id int,
	@iso TISO,
	@depo_type tinyint
AS
SET NOCOUNT ON;

DECLARE
	@client_type tinyint,
	@client_subtype tinyint,
	@is_resident bit

SELECT @client_type = CLIENT_TYPE, @client_subtype = CLIENT_SUBTYPE, @is_resident = IS_RESIDENT 
FROM dbo.CLIENTS (NOLOCK)
WHERE CLIENT_NO = @client_no


SET @bal_acc = 4405 + CASE WHEN @iso = 'GEL' THEN 0 ELSE 10 END 

EXEC dbo.on_user_depo_sp_get_depo_accrual_bal_acc
	@bal_acc = @bal_acc OUTPUT,
	@depo_bal_acc = @depo_bal_acc,
	@client_no = @client_no,
	@prod_id = @prod_id,
	@iso = @iso,
	@depo_type = @depo_type


RETURN 0
GO
