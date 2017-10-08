SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- შიდა პროცედურა საბუთის შესაცვლელად. პირდაპირ ნუ გამოიყენებთ. იხმარეთ ჩვეულებრივი dbo.UPDATE_DOC

CREATE PROCEDURE [dbo].[_INTERNAL_UPDATE_DOC]
  @rec_id int,
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
	RAISERROR ('ÃÄÁÄÔÉÓ ÀÍÂÀÒÉÛÕ ÀÒ ÌÏÉÞÄÁÍÀ.', 16, 1)
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

UPDATE dbo.OPS_0000 WITH (ROWLOCK)
SET 
	[UID] = [UID] + 1,
	DOC_DATE = @doc_date,
	DOC_DATE_IN_DOC = @doc_date_in_doc,
	ISO = @iso,
	AMOUNT = @amount,
	AMOUNT_EQU = @amount_equ,
	DOC_NUM = @doc_num,
	OP_CODE = @op_code,
	DEBIT_ID = @debit_id,
	CREDIT_ID = @credit_id,
	REC_STATE = @rec_state,
	BNK_CLI_ID = @bnk_cli_id,
	DESCRIP = @descrip,
	PARENT_REC_ID = @parent_rec_id,
	[OWNER] = @owner,
	DOC_TYPE = @doc_type,
	ACCOUNT_EXTRA = @account_extra,
	PROD_ID = @prod_id,
	FOREIGN_ID = @foreign_id,
	CHANNEL_ID = @channel_id,
	DEPT_NO = @dept_no,
	BRANCH_ID = dbo.dept_branch_id(@dept_no),
	IS_SUSPICIOUS = @is_suspicious,
	CASH_AMOUNT = @cash_amount,
	CASHIER = @cashier,
	CHK_SERIE = @chk_serie,
	TREASURY_CODE = @treasury_code,
	TAX_CODE_OR_PID = @tax_code_or_pid,
	RELATION_ID = @relation_id,
	FLAGS = @flags
WHERE REC_ID = @rec_id
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
