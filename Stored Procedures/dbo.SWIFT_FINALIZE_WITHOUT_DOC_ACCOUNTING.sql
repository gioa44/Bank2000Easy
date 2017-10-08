SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SWIFT_FINALIZE_WITHOUT_DOC_ACCOUNTING]
  @doc_rec_id int,
  @user_id int
AS
  SET NOCOUNT ON

  DECLARE
	@r int

  UPDATE dbo.SWIFT_DOCS_IN
  SET SWIFT_REC_STATE=60
  WHERE REC_ID=@doc_rec_id
  IF (@@ROWCOUNT<>1) OR (@@ERROR <> 0) OR (@r <> 0) BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) RETURN (1) END

  INSERT INTO SWIFT_DOCS_IN_CHANGES (DOC_REC_ID,USER_ID,DESCRIP) VALUES (@doc_rec_id,@user_id,'ÓÀÁÖÈÉÓ ÓÔÀÔÖÓÉÓ ÝÅËÉËÄÁÀ: ( 60 )');
  IF @@ERROR<>0 BEGIN RAISERROR ('ÛÄÝÃÏÌÀ.',16,1) RETURN (1) END

  
  UPDATE dbo.DOCS
  SET REC_STATE = 22
  WHERE REC_ID = @doc_rec_id
  IF (@@ROWCOUNT<>1) OR (@@ERROR <> 0) OR (@r <> 0) BEGIN RAISERROR('ÛÄÝÃÏÌÀ ÓÀÁÖÈÉÓ ÛÄÝÅËÉÓÀÓ.',16,1) RETURN (1) END

  INSERT INTO dbo.DOC_CHANGES (DOC_REC_ID,[USER_ID],DESCRIP) VALUES (@doc_rec_id,@user_id,'ÓÀÁÖÈÉÓ ÀÅÔÏÒÉÆÀÝÉÀ : 2 -> 3 (SWIFT)')
  IF @@ERROR<>0 RETURN(6)

GO
