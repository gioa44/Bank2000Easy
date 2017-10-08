SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auto_transfer_deposit_taxes]
AS

SET NOCOUNT ON;

DECLARE
	@today smalldatetime
SET @today = convert(smalldatetime,floor(convert(real,getdate())))


DECLARE
	@r int,
	@account_n TACCOUNT,
	@account_f TACCOUNT,
	@head_branch_id int

SET @head_branch_id = dbo.bank_head_branch_id()

DECLARE @ACC_SET TABLE(ACC_ID_N int NOT NULL, ACC_ID_F int NULL, ISO CHAR(3) NOT NULL)

EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP_V', @account_f OUTPUT
EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RP', @account_n OUTPUT

INSERT INTO @ACC_SET(ACC_ID_N, ACC_ID_F, ISO)
SELECT dbo.acc_get_acc_id(@head_branch_id, @account_n, 'GEL'), dbo.acc_get_acc_id(@head_branch_id, @account_f, ISO), ISO
FROM dbo.VAL_CODES
WHERE ISO <> 'GEL' AND IS_DISABLED = 0

EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP_V', @account_f OUTPUT
EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRP', @account_n OUTPUT

INSERT INTO @ACC_SET(ACC_ID_N, ACC_ID_F, ISO)
SELECT dbo.acc_get_acc_id(@head_branch_id, @account_n, 'GEL'), dbo.acc_get_acc_id(@head_branch_id, @account_f, ISO), ISO
FROM dbo.VAL_CODES
WHERE ISO <> 'GEL' AND IS_DISABLED = 0

EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ_V', @account_f OUTPUT
EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_RJ', @account_n OUTPUT

INSERT INTO @ACC_SET(ACC_ID_N, ACC_ID_F, ISO)
SELECT dbo.acc_get_acc_id(@head_branch_id, @account_n, 'GEL'), dbo.acc_get_acc_id(@head_branch_id, @account_f, ISO), ISO
FROM dbo.VAL_CODES
WHERE ISO <> 'GEL' AND IS_DISABLED = 0

EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ_V', @account_f OUTPUT
EXEC dbo.GET_SETTING_ACC 'DEPO_TAX_ACC_NRJ', @account_n OUTPUT
INSERT INTO @ACC_SET(ACC_ID_N, ACC_ID_F, ISO)

SELECT dbo.acc_get_acc_id(@head_branch_id, @account_n, 'GEL'), dbo.acc_get_acc_id(@head_branch_id, @account_f, ISO), ISO
FROM dbo.VAL_CODES
WHERE ISO <> 'GEL' AND IS_DISABLED = 0

DECLARE
	@acc_id_n int,
	@acc_id_f int,
	@iso_f CHAR(3)

DECLARE
	@rec_id_1 int,
	@rec_id_2 int,
	@amount_d money,
	@amount_c money,
	@amount money
	
DELETE FROM @ACC_SET
WHERE ACC_ID_F IS NULL
	
DECLARE cc_1 CURSOR
FOR SELECT DISTINCT ACC_ID_N, ACC_ID_F, ISO
FROM @ACC_SET 

OPEN cc_1

FETCH NEXT FROM cc_1
INTO @acc_id_n,	@acc_id_f, @iso_f

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @amount_d = - dbo.acc_get_balance(@acc_id_f, @today, 1, 0, 2)	
	IF @amount_d <= $0.00 GOTO _next

	SET @amount_c = ROUND(dbo.get_equ(@amount_d, @iso_f, @today), 2) 
	IF @amount_c = $0.00 GOTO _next

	EXEC @r = dbo.ADD_CONV_DOC4
	  @rec_id_1 = @rec_id_1 OUTPUT,        
	  @rec_id_2 = @rec_id_2 OUTPUT,        
	  @user_id =  2,
	  @iso_d = @iso_f,
	  @iso_c = 'GEL',
	  @amount_d = @amount_d,
	  @amount_c = @amount_c,
	  @debit_id = @acc_id_f,
	  @credit_id = @acc_id_n,
	  @doc_date = @today,
	  @op_code = 'FXDP',
	  @descrip1 = 'ÃÄÐÏÆÉÔÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÄÁÉÓ ÓÀÛÄÌÏÓÀÅËÏ (Clearing)',
	  @descrip2 = 'ÃÄÐÏÆÉÔÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÄÁÉÓ ÓÀÛÄÌÏÓÀÅËÏ (Clearing)',
	  @rec_state = 20,
	  @dept_no = @head_branch_id

	IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE cc_1; DEALLOCATE cc_1; RETURN (1); END 

_next:
	FETCH NEXT FROM cc_1
	INTO @acc_id_n,	@acc_id_f, @iso_f
END

CLOSE cc_1
DEALLOCATE cc_1

DECLARE
	@tax_revert_acc_id int
	
EXEC @r = dbo.depo_sp_get_tax_revert_acc
	@iso = 'GEL',
	@tax_revert_acc_id = @tax_revert_acc_id OUTPUT
IF @@ERROR <> 0 OR @r <> 0 RETURN (1);

DECLARE cc_1_2 CURSOR
FOR SELECT DISTINCT ACC_ID_N
FROM @ACC_SET 

OPEN cc_1_2

FETCH NEXT FROM cc_1_2
INTO @acc_id_n

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @amount_d = - dbo.acc_get_balance(@acc_id_n, @today, 1, 0, 2)	
	IF @amount_d <= $0.00 GOTO _next_1_2

	SET @amount_c = dbo.acc_get_balance(@tax_revert_acc_id, @today, 1, 0, 2)
	IF @amount_c <= $0.00 GOTO _next_1_2
	
	IF @amount_d <= @amount_c
		SET @amount = @amount_d
	ELSE
		SET @amount = @amount_c

	EXEC @r = dbo.ADD_DOC4
		@rec_id = @rec_id_1 OUTPUT,
		@user_id = 2,
		@doc_type = 98,
		@doc_date = @today,
		@debit_id = @acc_id_n,
		@credit_id = @tax_revert_acc_id,
		@iso = 'GEL',
		@amount = @amount,
		@rec_state = 20,
		@descrip = 'ÆÄÃÌÄÔÀÃ ÂÀÃÀáÉËÉ ÓÀÛÌÏÓÀÅËÏÓ ÃÀÁÒÖÍÄÁÀ (Clearing)',
		@op_code = 'DPTXR',
		@dept_no = @head_branch_id

	IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE cc_1_2; DEALLOCATE cc_1_2; RETURN (1); END 

_next_1_2:
	FETCH NEXT FROM cc_1_2
	INTO @acc_id_n
END

CLOSE cc_1_2
DEALLOCATE cc_1_2

DECLARE
	@debit_id int,
	@credit_id int,
	@descrip varchar(150),
	@sender_bank_code varchar(37),
	@sender_bank_name varchar(105),
	@sender_acc varchar(37),
	@sender_acc_name varchar(105),
	@sender_tax_code varchar(11),
	@transit_account varchar(37),
	@saxazkod varchar(9)
	
SELECT @sender_bank_code = CODE9 FROM dbo.DEPTS (NOLOCK) WHERE DEPT_NO = @head_branch_id
SELECT @sender_bank_name = DESCRIP FROM dbo.BANKS (NOLOCK) WHERE CODE9 = @sender_bank_code

SELECT @sender_tax_code = VALS FROM dbo.INI_STR (NOLOCK) WHERE IDS = 'BANK_TAX_CODE'

SELECT @transit_account = VALS FROM dbo.INI_INT (NOLOCK) WHERE IDS = 'CORR_ACC_NA'
SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @transit_account, 'GEL')

SET @saxazkod = '400771006'
SELECT @descrip = DESCRIP 
FROM dbo.SAXAZCODES_4 (NOLOCK) 
WHERE ID = SUBSTRING(@saxazkod, 6, 4)

DECLARE cc_2 CURSOR
FOR SELECT DISTINCT ACC_ID_N
FROM @ACC_SET 

OPEN cc_2

FETCH NEXT FROM cc_2
INTO @debit_id

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @amount = - dbo.acc_get_balance(@debit_id, @today, 1, 0, 2)	
	IF @amount <= $0.00 GOTO _next_2

	SET @sender_acc_name = dbo.acc_get_name(@debit_id)
	SET @sender_acc = dbo.acc_get_account(@debit_id)
	
	EXEC @r = dbo.ADD_DOC4
		@rec_id = @rec_id_1 OUTPUT,
		@user_id = 2,
		@doc_type = 102,
		@doc_date = @today,
		@doc_date_in_doc = @today,
		@debit_id = @acc_id_n,
		@credit_id = @credit_id,
		@iso = 'GEL',
		@amount = @amount,
		@rec_state = 20,
		@descrip = @descrip,
		@op_code = 'DPTT',
		@dept_no = @head_branch_id,

		@sender_bank_code = @sender_bank_code,
		@sender_bank_name = @sender_bank_name,
		@sender_acc = @sender_acc,
		@sender_acc_name = @sender_acc_name,
		@sender_tax_code = @sender_tax_code,

		@receiver_bank_code = 220101222,
		@receiver_bank_name = 'Ø.ÈÁÉËÉÓÉ, "ÓÀáÄËÌßÉ×Ï áÀÆÉÍÀ"',
		@receiver_acc = 200122900,
		@receiver_acc_name = 'ÁÉÖãÄÔÉÓ ÛÄÌÏÓÖËÏÁÄÁÉÓ ÄÒÈÉÀÍÉ ÀÍÂÀÒÉÛÉ,(ÌÓáÅÉË ÂÀÃÀÌáÃÄËÈÀ ÉÍÓÐÄØÝÉÀ)',
		@receiver_tax_code = '203834725',

		@extra_info = 'ÃÄÐÏÆÉÔÆÄ ÃÀÒÉÝáÖËÉ ÐÒÏÝÄÍÔÄÁÉÓ ÓÀÛÄÌÏÓÀÅËÏ',

		@rec_date = @today,
		@saxazkod = @saxazkod
  
	IF @@ERROR <> 0 OR @r <> 0 BEGIN CLOSE cc_2; DEALLOCATE cc_2; RETURN (1); END

_next_2:
	FETCH NEXT FROM cc_2
	INTO @debit_id
END

CLOSE cc_2
DEALLOCATE cc_2
GO
