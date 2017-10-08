SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[auto_open_account]
  @acc_id int OUTPUT,
  @branch_id int,
  @account TACCOUNT,
  @iso TISO,
  @user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@template_branch_id int,
	@template_acc_id int

EXEC dbo.GET_SETTING_INT 'AUTO_ACC_TEMPL_BR', @template_branch_id OUTPUT

IF @template_branch_id = @branch_id
BEGIN
	RAISERROR ('Cannot automaticaly open account for template branch', 16, 1)
	RETURN -1
END

DECLARE @r int
DECLARE @bal_acc_alt TBAL_ACC
DECLARE @act_pas tinyint
DECLARE @rec_state tinyint
DECLARE @descrip varchar(100)
DECLARE @descrip_lat varchar(100)
DECLARE @acc_type tinyint
DECLARE @acc_subtype int
DECLARE @client_no int
DECLARE @period smalldatetime
DECLARE @tariff smallint
DECLARE @product_no int
DECLARE @min_amount money
DECLARE @min_amount_new money
DECLARE @min_amount_check_date smalldatetime
DECLARE @blocked_amount money
DECLARE @block_check_date smalldatetime
DECLARE @prof_loss_acc TACCOUNT
DECLARE @flags int
DECLARE @remark varchar(100)
DECLARE @code_phrase varchar(20)
DECLARE @bal_acc_old TBAL_ACC
DECLARE @responsible_user_id int


SELECT TOP 1
	@template_acc_id = ACC_ID,
	@bal_acc_alt = BAL_ACC_ALT,
	@act_pas = ACT_PAS,
	@rec_state = REC_STATE,
	@descrip = DESCRIP,
	@descrip_lat = DESCRIP_LAT,
	@acc_type = ACC_TYPE,
	@acc_subtype = ACC_SUBTYPE,
	@client_no = CLIENT_NO,
	@period = PERIOD,
	@tariff = TARIFF,
	@product_no = PRODUCT_NO,
	@min_amount = MIN_AMOUNT,
	@min_amount_new = MIN_AMOUNT_NEW,
	@min_amount_check_date = MIN_AMOUNT_CHECK_DATE,
	@blocked_amount = BLOCKED_AMOUNT,
	@block_check_date = BLOCK_CHECK_DATE,
	@prof_loss_acc = PROF_LOSS_ACC,
	@flags = FLAGS,
	@remark = REMARK,
	@code_phrase = CODE_PHRASE,
	@responsible_user_id = RESPONSIBLE_USER_ID,
	@bal_acc_old = BAL_ACC_OLD
FROM dbo.ACCOUNTS
WHERE BRANCH_ID = @template_branch_id AND ACCOUNT = @account AND ISO = @iso

IF @template_acc_id IS NULL
BEGIN
	RAISERROR ('ÛÀÁËÏÍÖÒÉ ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ', 16, 1)
	RETURN -1
END

BEGIN TRAN

EXECUTE @r = dbo.ADD_ACCOUNT
   @acc_id = @acc_id OUTPUT
  ,@user_id = @user_id
  ,@dept_no = @branch_id
  ,@account = @account
  ,@iso = @iso
  ,@bal_acc_alt = @bal_acc_alt
  ,@act_pas = @act_pas
  ,@rec_state = @rec_state
  ,@descrip = @descrip
  ,@descrip_lat = @descrip_lat
  ,@acc_type = @acc_type
  ,@acc_subtype = @acc_subtype
  ,@client_no = @client_no
  ,@period = @period
  ,@tariff = @tariff
  ,@product_no = @product_no
  ,@min_amount = @min_amount
  ,@min_amount_new = @min_amount_new
  ,@min_amount_check_date = @min_amount_check_date
  ,@blocked_amount = @blocked_amount
  ,@block_check_date = @block_check_date
  ,@prof_loss_acc = @prof_loss_acc
  ,@flags = @flags
  ,@remark = @remark
  ,@code_phrase = @code_phrase
  ,@bal_acc_old = @bal_acc_old
  ,@responsible_user_id = @responsible_user_id

IF @r <> 0 OR @@ERROR <> 0
BEGIN
	RAISERROR ('ÀÍÂÀÒÉÛÉ ÅÄÒ ÂÀÉáÓÍÀ ÀÅÔÏÌÀÔÖÒÀÃ', 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK
	RETURN -2
END

INSERT INTO dbo.ACC_ATTRIBUTES (ACC_ID, ATTRIB_CODE, ATTRIB_VALUE)
SELECT @acc_id, ATTRIB_CODE, ATTRIB_VALUE
FROM dbo.ACC_ATTRIBUTES
WHERE ACC_ID = @template_acc_id

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN -3 END

INSERT INTO dbo.ACCOUNTS_USR ([USER_ID], ACC_ID)
SELECT [USER_ID], @acc_id
FROM dbo.ACCOUNTS_USR
WHERE ACC_ID = @template_acc_id

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN -3 END

INSERT INTO dbo.ACCOUNTS_CLASSIF (ACC_ID, [ID])
SELECT @acc_id, [ID]
FROM dbo.ACCOUNTS_CLASSIF
WHERE ACC_ID = @template_acc_id

IF @@ERROR <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN -3 END

COMMIT TRAN
GO
