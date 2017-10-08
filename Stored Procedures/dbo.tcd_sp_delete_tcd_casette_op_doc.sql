SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_delete_tcd_casette_op_doc]
(
	@user_id int,	
	@op_id int
)
AS
BEGIN
	DECLARE @r int,
			@doc_rec_id int,
			@internal_transaction bit

	SET @internal_transaction = 0
	IF @@TRANCOUNT = 0
	BEGIN
		BEGIN TRAN
		SET @internal_transaction = 1
	END
	
	SELECT @doc_rec_id = DOC_REC_ID
	FROM dbo.TCD_CASETTE_OPS
	WHERE OP_ID=@op_id
	
	IF @doc_rec_id IS NOT NULL
	BEGIN
		EXEC @r = dbo.DELETE_DOC
			@rec_id = @doc_rec_id,
			@user_id = @user_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR DELETE DOC' , 16, 1); RETURN (1); END	
	END

	IF @internal_transaction = 1
		COMMIT
	RETURN 0
END
GO
