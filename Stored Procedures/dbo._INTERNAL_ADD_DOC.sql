SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[_INTERNAL_ADD_DOC]
  @rec_id int OUTPUT,			
  @owner int = NULL,			
  @doc_type smallint,			
  @doc_date smalldatetime,		
  @doc_date_in_doc smalldatetime = NULL,
  @debit_id int,
  @credit_id int,
  @iso TISO = 'GEL',			
  @amount money,				
  @rec_state tinyint = 0,		
  @descrip varchar(150) = NULL,	
  @op_code TOPCODE = '',		
  @parent_rec_id int = 0,		
  @doc_num int = NULL,	
  @bnk_cli_id int = NULL,		
  @account_extra TACCOUNT = NULL,
  @dept_no int = null,			
  @prod_id int = null,			
  @foreign_id int = null,		
  @channel_id int = 0,			
  @is_suspicious bit = 0,		
  @cash_amount money = NULL,
  @cashier int = NULL,
  @chk_serie varchar(4) = NULL,
  @treasury_code varchar(9) = NULL,
  @tax_code_or_pid varchar(11) = NULL,
  @relation_id int = NULL,
  @flags int = 0,
  @lat bit = 0
AS

IF @amount IS NULL OR @iso IS NULL OR @owner IS NULL OR @rec_state IS NULL OR @doc_type IS NULL
BEGIN
    RAISERROR ('<ERR>Invalid parameters</ERR>',16,1)
	RETURN 999
END

IF @is_suspicious IS NULL
	SET @is_suspicious = 0
IF @flags IS NULL
	SET @flags = 0
IF @parent_rec_id IS NULL
	SET @parent_rec_id = 0

DECLARE @dt_open smalldatetime
SET @dt_open = dbo.bank_open_date ()

IF ISNULL(@doc_date, '19000101') < @dt_open
BEGIN
  IF @lat = 0 
       RAISERROR ('<ERR>ÞÅÄËÉ ÈÀÒÉÙÉÈ ÓÀÁÖÈÉÓ ÃÀÌÀÔÄÁÀ ÀÒ ÛÄÉÞËÄÁÀ</ERR>',16,1)
  ELSE RAISERROR ('<ERR>Cannot add documets with an old date</ERR>',16,1)
  RETURN (3)
END

IF @debit_id IS NULL
BEGIN 
	RAISERROR ('ÃÄÁÄÔÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ.', 16, 1)
	RETURN 101
END
  
IF @credit_id IS NULL
BEGIN 
	RAISERROR ('ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ.', 16, 1)
	RETURN 102
END

IF @credit_id = @debit_id
BEGIN 
	RAISERROR ('ÃÄÁÄÔÉÓ ÃÀ ÊÒÄÃÉÔÉÓ ÀÍÂÀÒÉÛÉ ÄÒÈÍÀÉÒÉÀ', 16, 1)
	RETURN 103
END

IF @doc_num IS NULL
BEGIN
	DECLARE 
		@doc_num_type tinyint

	SET @doc_num_type = dbo.get_doc_num_type (@doc_type)
	IF  @doc_num_type > 0
	BEGIN
		UPDATE dbo.DOC_NUMBERING WITH (ROWLOCK)
		SET @doc_num = LAST_USED_NUM = LAST_USED_NUM + 1
		WHERE DOC_NUM_TYPE = @doc_num_type 
	END
END

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE @amount_equ money
SET @amount = round(@amount, 2)
SET @amount_equ = dbo.get_equ(@amount, @iso, @doc_date)

INSERT INTO dbo.OPS_0000 WITH (ROWLOCK) ([UID],DOC_DATE,DOC_DATE_IN_DOC,ISO,AMOUNT,AMOUNT_EQU,DOC_NUM,OP_CODE,DEBIT_ID,CREDIT_ID,REC_STATE,BNK_CLI_ID,DESCRIP,PARENT_REC_ID,OWNER,DOC_TYPE,ACCOUNT_EXTRA,PROD_ID,FOREIGN_ID,CHANNEL_ID,DEPT_NO,IS_SUSPICIOUS,CASH_AMOUNT,CASHIER,CHK_SERIE,TREASURY_CODE,TAX_CODE_OR_PID,RELATION_ID,FLAGS,BRANCH_ID)
VALUES (0,@doc_date,@doc_date_in_doc,@iso,@amount,@amount_equ,@doc_num,@op_code,@debit_id,@credit_id,@rec_state,@bnk_cli_id,@descrip,@parent_rec_id,@owner,@doc_type,@account_extra,@prod_id,@foreign_id,@channel_id,@dept_no,@is_suspicious,@cash_amount,@cashier,@chk_serie,@treasury_code,@tax_code_or_pid,@relation_id,@flags,dbo.dept_branch_id(@dept_no))
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 3 END

SET @rec_id = SCOPE_IDENTITY()

IF @parent_rec_id > 0
BEGIN
	UPDATE dbo.OPS_0000 WITH (ROWLOCK)
	SET PARENT_REC_ID = -1, UID = UID + 1
	WHERE REC_ID = @parent_rec_id AND ISNULL(PARENT_REC_ID, 0) <> -1
	
	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 4 END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
