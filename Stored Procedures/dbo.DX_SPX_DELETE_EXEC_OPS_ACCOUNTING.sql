SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DX_SPX_DELETE_EXEC_OPS_ACCOUNTING]
  @docs_rec_id int,
  @oid int,
  @user_id int
AS
  SET NOCOUNT ON
  IF @docs_rec_id IS NOT NULL BEGIN
    DECLARE 
      @rec_state tinyint
    SELECT @rec_state=REC_STATE FROM DOCS_ALL WHERE REC_ID=@docs_rec_id

    IF @rec_state IS NULL BEGIN
      RETURN (2)
    END

    IF @rec_state > 0 BEGIN
      RAISERROR('ÏÐÄÒÀÝÉÀÈÓÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÉ ÀÅÔÏÒÉÆÄÁÖËÉÀ!', 16, 1)
      RETURN (1)
    END
    ELSE BEGIN
      DECLARE @rc int
      EXEC @rc=dbo.DELETE_DOC @rec_id=@docs_rec_id, @user_id=@user_id
      IF @@ERROR<>0 OR @rc<>0 BEGIN
        RAISERROR('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ßÀÛËÉÓ ÃÒÏÓ, ÃÀÖÊÀÅÛÉÒÃÉÈ ÓÉÓÔÄÌÖÒ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ', 16, 1)
        RETURN (1)
      END
    END
  END
  RETURN (0)
GO
