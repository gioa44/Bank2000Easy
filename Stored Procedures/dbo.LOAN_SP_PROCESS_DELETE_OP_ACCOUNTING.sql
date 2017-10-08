SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[LOAN_SP_PROCESS_DELETE_OP_ACCOUNTING]
	@doc_rec_id int,
	@op_id int,
	@user_id int,
	@by_processing bit = 0
AS
SET NOCOUNT ON

IF ISNULL(@doc_rec_id, 0) <> 0
BEGIN
	DECLARE 
		@rec_state tinyint
	SELECT @rec_state=REC_STATE FROM dbo.OPS_0000 (NOLOCK) WHERE REC_ID=@doc_rec_id

	IF @rec_state IS NULL BEGIN
		RETURN (2)
	END

    IF @rec_state > 0 BEGIN
      RAISERROR('ÏÐÄÒÀÝÉÀÈÓÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÉ ÀÅÔÏÒÉÆÄÁÖËÉÀ', 16, 1)
      RETURN (1)
    END
    ELSE BEGIN
      DECLARE @rc int
      EXEC @rc=dbo.DELETE_DOC @rec_id=@doc_rec_id, @user_id=@user_id, @check_saldo = 1
      IF @@ERROR<>0 OR @rc<>0 BEGIN
        RAISERROR('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ßÀÛËÉÓ ÃÒÏÓ, ÃÀÖÊÀÅÛÉÒÃÉÈ ÓÉÓÔÄÌÖÒ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ', 16, 1)
        RETURN (1)
      END
    END
  END
  RETURN (0)


GO
