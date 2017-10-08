SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SWIFT_DEL_FINALIZE_DOC_ACCOUNTING]
  @rec_id int,
  @user_id int
AS
  SET NOCOUNT ON
  DECLARE @doc_rec_id int
  SELECT @doc_rec_id=FIN_DOC_REC_ID FROM dbo.SWIFT_DOCS_IN WHERE REC_ID=@rec_id

  IF @doc_rec_id IS NOT NULL BEGIN
    DECLARE 
      @rec_state tinyint
    SELECT @rec_state=REC_STATE FROM DOCS_ALL WHERE REC_ID=@doc_rec_id

    IF @rec_state IS NULL BEGIN
      RAISERROR('ÏÐÄÒÀÝÉÀÈÓÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
      RETURN (2)
    END

    IF NOT (@rec_state < 20) BEGIN
      RAISERROR('ÏÐÄÒÀÝÉÀÈÓÀÍ ÃÀÊÀÅÛÉÒÄÁÖËÉ ÓÀÁÖÈÉ ÀÅÔÏÒÉÆÄÁÖËÉÀ', 16, 1)
      RETURN (1)
    END
    ELSE BEGIN
      DECLARE @rc int
      EXEC @rc=dbo.DELETE_DOC @rec_id=@doc_rec_id, @user_id=@user_id
      IF @@ERROR<>0 OR @rc<>0 BEGIN
        RAISERROR('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ßÀÛËÉÓ ÃÒÏÓ, ÃÀÖÊÀÅÛÉÒÃÉÈ ÓÉÓÔÄÌÖÒ ÀÃÌÉÍÉÓÔÒÀÔÏÒÓ', 16, 1)
        RETURN (1)
      END
      UPDATE dbo.SWIFT_DOCS_IN
      SET FIN_DOC_REC_ID=null, SWIFT_REC_STATE=50
      WHERE REC_ID=@rec_id
      IF (@@ROWCOUNT<>1) OR (@@ERROR <> 0) BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÂÀÃÀáÖÒÅÉÓ ÂÀÖØÌÄÁÉÓÀÓ',16,1) RETURN (1) END

      INSERT INTO SWIFT_DOCS_IN_CHANGES (DOC_REC_ID,USER_ID,DESCRIP) VALUES (@rec_id,@user_id,'ÓÀÁÖÈÉÓ ÓÔÀÔÖÓÉÓ ÝÅËÉËÄÁÀ: ( 50 )');
      IF @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN (1) END
    END
  END
  RETURN (0)

GO
