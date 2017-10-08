SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_authorize_tcd_casette_op]
(
	@op_id int,
	@user_id int
)
AS

BEGIN

	BEGIN TRAN

	DECLARE 
		@doc_rec_id int,
		@r int

	UPDATE dbo.TCD_CASETTE_OPS WITH (UPDLOCK)
	SET [STATE] = 255,
		AUTH_OWNER = @user_id,
		AUTH_DATE = GETDATE()
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN ROLLBACK; RAISERROR ('ERROR UPDATE TCD_CASETTE_OPS' , 16, 1); RETURN (1); END

	UPDATE TC WITH (UPDLOCK)
	SET TC.PENDING = 0
	FROM dbo.TCD_CASETTES TC
		INNER JOIN dbo.TCD_CASETTE_OP_DETAILS TCOD ON TCOD.CASETTE_SERIAL_ID = TC.CASETTE_SERIAL_ID
		INNER JOIN dbo.TCD_CASETTE_OPS TCO ON TCOD.OP_ID = TCO.OP_ID
	WHERE TCO.OP_ID = @op_id
	IF @@ERROR <> 0 BEGIN ROLLBACK; RAISERROR ('ERROR UPDATE TCD_CASETTES' , 16, 1); RETURN (1); END

	SELECT @doc_rec_id = DOC_REC_ID
	FROM dbo.TCD_CASETTE_OPS
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN ROLLBACK; RAISERROR ('TCD_CASETTE_OPS DATA ERROR' , 16, 1); RETURN (1); END
	
	IF @doc_rec_id IS NOT NULL
	BEGIN 
		EXEC @r = CHANGE_DOC_STATE
				@rec_id = @doc_rec_id,
				@user_id = @user_id,
				@new_rec_state = 20
		IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK; RAISERROR ('ERROR DOCUMENT CHANGE STATE' , 16, 1); RETURN (1); END
	END

	COMMIT
	RETURN 0
END
GO