SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_PAYMENTS_CARD_INFO] @rec_id int OUTPUT,
	@rec_state int = 0,
	@branch_id int = 0,
	@account varchar(20),
	@terminal_id varchar(8),
	@amount TAMOUNT,
	@ccy TISO,
	@ref_num varchar(12),
	@card_id varchar(19),
	@exp_date varchar(4),
	@appr_code varchar(4000),
	@result varchar(4000)

AS
SET NOCOUNT ON

INSERT INTO dbo.PAYMENTS_PC_INFO(REC_STATE, BRANCH_ID, ACCOUNT, TERMINAL_ID, AMOUNT, CCY, REF_NUM, CARD_ID, EXP_DATE, APPR_CODE, RESULT)
VALUES(@rec_state, @branch_id, @account, @terminal_id, @amount, @ccy, @ref_num, @card_id, @exp_date, @appr_code, @result)

IF @@ERROR <> 0
BEGIN
	RAISERROR('ÐËÀÓÔÉÊÖÒ ÁÀÒÀÈÆÄ ÉÍ×ÏÒÌÀÝÉÀ ÅÄÒ ÜÀÄÌÀÔÀ!',16,1)
	RETURN 1
END

SET @rec_id = SCOPE_IDENTITY()

RETURN 0
GO
