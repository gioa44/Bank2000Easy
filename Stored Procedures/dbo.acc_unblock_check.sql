SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[acc_unblock_check]
	@acc_id int,
	@block_id int,
	@product_id varchar(20)
AS

SET NOCOUNT ON;

IF @product_id = '#DEPOSIT'
BEGIN
	DECLARE
		@depo_id int

	SELECT @depo_id = convert(int, USER_DATA)
	FROM dbo.ACCOUNTS_BLOCKS (NOLOCK)
	WHERE ACC_ID = @acc_id AND BLOCK_ID = @block_id 

	DECLARE
		@state tinyint

	SELECT @state = [STATE]
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @state IS NOT NULL AND @state > 40 AND @state < 240
	BEGIN
		RAISERROR ('ÁËÏÊÉÓ ÌÏáÓÍÀ ÖÍÃÀ ÌÏáÃÄÓ ÀÍÀÁÒÉÃÀÍ!', 16, 1);
		RETURN 1;
	END
END

RETURN 0;
GO
