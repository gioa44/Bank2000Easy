SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_block_amount] (
	@acc_id int,
	@iso TISO = 'GEL',
	@amount money,
	@fee money = $0.00,
	@user_id int,
	@product_id varchar(20),
	@auto_unblock_date smalldatetime,
	@user_data sql_variant = null,
	@block_id int OUTPUT
)
AS

SET NOCOUNT ON;

DECLARE @r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

INSERT INTO dbo.ACCOUNTS_BLOCKS (ACC_ID,IS_ACTIVE,ISO,AMOUNT,FEE,BLOCKED_BY_USER,BLOCKED_BY_PRODUCT,BLOCK_DATE_TIME,AUTO_UNBLOCK_DATE,USER_DATA)
VALUES (@acc_id, 1, @iso, @amount,	@fee, @user_id, @product_id, GETDATE(), @auto_unblock_date, @user_data)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

SET @block_id = SCOPE_IDENTITY()

UPDATE dbo.ACCOUNTS
SET BLOCKED_AMOUNT = ISNULL(BLOCKED_AMOUNT, $0.00) + ISNULL(@amount, $0.00) + ISNULL(@fee, $0.00),
	BLOCK_CHECK_DATE = (SELECT MIN(AUTO_UNBLOCK_DATE) FROM dbo.ACCOUNTS_BLOCKS WHERE ACC_ID = @acc_id AND IS_ACTIVE = 1)
WHERE ACC_ID = @acc_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

EXEC @r = dbo.CHECK_SALDO @acc_id = @acc_id, @doc_date = @auto_unblock_date, @lat = 0
IF @r <> 0 OR @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
