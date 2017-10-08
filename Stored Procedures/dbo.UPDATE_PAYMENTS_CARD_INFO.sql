SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[UPDATE_PAYMENTS_CARD_INFO]
	@rec_id int,
	@doc_rec_id int = 0,
	@rec_state int,
	@ref_num varchar(12),
	@appr_code varchar(4000),
	@result varchar(4000)
AS
SET NOCOUNT ON

UPDATE dbo.PAYMENTS_PC_INFO
SET DOC_REC_ID = @doc_rec_id,
	REC_STATE = @rec_state,
	REF_NUM = @ref_num,
	APPR_CODE = @appr_code,
	RESULT = @result
WHERE REC_ID= @rec_id

IF @@ERROR <> 0
BEGIN
	RAISERROR('ÐËÀÓÔÉÊÖÒ ÁÀÒÀÈÆÄ ÉÍ×ÏÒÌÀÝÉÀ ÅÄÒ ÂÀÍÀáËÃÀ!',16,1)
	RETURN 1
END

RETURN 0
GO
