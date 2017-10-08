SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AUTHORIZE_PLAT_V]
  @rec_id int,
  @uid int = null,			-- საბუთის ბოლოს ცვლილების ნომერი. თუ ნულია, აღარ ვუყურებთ
  @user_id int,
  @dt smalldatetime = 0
AS

SET NOCOUNT ON

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE @r int
	
EXEC @r = dbo.CHANGE_DOC_STATE @rec_id, @uid, @user_id = @user_id, @new_rec_state = 22
IF @@ERROR <>0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
