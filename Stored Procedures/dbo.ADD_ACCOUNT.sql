SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ADD_ACCOUNT] (
	@acc_id int OUTPUT,
	@user_id int = NULL,		-- ÅÉÍ ÀÌÀÔÄÁÓ ÀÍÂÀÒÉÛÓ
	@dept_no int = NULL,		-- ×ÉËÉÀËÉ
	@account TACCOUNT = NULL,
	@iso TISO = 'GEL',
	@bal_acc_alt TBAL_ACC,
	@act_pas tinyint = NULL,
	@rec_state tinyint = 1,
	@descrip varchar(100) = NULL,
	@descrip_lat varchar(100) = NULL,
	@acc_type tinyint = 1, 
	@acc_subtype int = NULL, 
	@client_no int = NULL,
	@date_open smalldatetime = NULL,
	@period smalldatetime = NULL,
	@date_close smalldatetime = NULL,
	@tariff smallint = NULL,
	@product_no int = NULL,
	@min_amount money = $0.0000,
	@min_amount_new money = $0.0000,
	@min_amount_check_date smalldatetime = NULL,
	@min_amount_check_date_new smalldatetime = NULL,
	@blocked_amount money = NULL,
	@block_check_date smalldatetime = NULL,
	@prof_loss_acc TACCOUNT = NULL,
	@flags int = 0,
	@remark varchar(100) = NULL,
	@code_phrase varchar(20) = NULL,
	@bal_acc_old TBAL_ACC = NULL,
	@responsible_user_id int = NULL,
	@is_control bit = 0,
	@is_incasso bit = 0,
	@user_def_type int = NULL,
	@bal_acc2 TBAL_ACC = NULL,
	@bal_acc3 TBAL_ACC = NULL,

	@auto_acc_num_template varchar(100) = NULL, -- ÂÀÌÏÉÚÄÍÄÁÀ ÈÖ ACCOUNT IS NULL
	@auto_acc_num_min_value TACCOUNT = NULL		-- ÂÀÌÏÉÚÄÍÄÁÀ ÈÖ ACCOUNT IS NULL
) 
AS

SET NOCOUNT ON

SET @descrip = ISNULL(@descrip, '')
SET @descrip = LTRIM(RTRIM(@descrip))

IF @client_no IS NOT NULL AND @descrip = ''
BEGIN
	SELECT @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no
END
ELSE
IF @client_no IS NULL AND @descrip = ''
BEGIN
	SELECT @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
	FROM dbo.PLANLIST_ALT (NOLOCK)
	WHERE BAL_ACC = @bal_acc_alt
END

IF ISNULL(@descrip_lat, '') = ''
	SET @descrip_lat = @descrip

IF @act_pas IS NULL
	SELECT @act_pas = ACT_PAS
	FROM dbo.PLANLIST_ALT
	WHERE BAL_ACC = @bal_acc_alt

IF @date_open IS NULL
	SET @date_open = convert(smalldatetime,floor(convert(real,getdate())))

IF @responsible_user_id IS NULL
	SET @responsible_user_id = @user_id

DECLARE @r int

EXEC @r = dbo.ON_USER_BEFORE_ADD_ACCOUNT
	@user_id = @user_id OUTPUT,
	@dept_no = @dept_no OUTPUT,
	@account = @account OUTPUT,
	@iso = @iso OUTPUT,
	@bal_acc_alt = @bal_acc_alt OUTPUT,
	@act_pas = @act_pas OUTPUT,
	@rec_state = @rec_state OUTPUT,
	@descrip = @descrip OUTPUT,
	@descrip_lat = @descrip_lat OUTPUT,
	@acc_type = @acc_type OUTPUT, 
	@acc_subtype = @acc_subtype OUTPUT, 
	@client_no = @client_no OUTPUT,
	@date_open = @date_open OUTPUT,
	@period = @period OUTPUT,
	@tariff = @tariff OUTPUT,
	@product_no = @product_no OUTPUT,
	@min_amount = @min_amount OUTPUT,
	@min_amount_new = @min_amount_new OUTPUT,
	@min_amount_check_date = @min_amount_check_date OUTPUT,
	@blocked_amount = @blocked_amount OUTPUT,
	@block_check_date = @block_check_date OUTPUT,
	@prof_loss_acc = @prof_loss_acc OUTPUT,
	@flags = @flags OUTPUT,
	@remark = @remark OUTPUT,
	@code_phrase = @code_phrase OUTPUT,
	@bal_acc_old = @bal_acc_old OUTPUT,
	@responsible_user_id = @responsible_user_id OUTPUT,
	@is_control = @is_control OUTPUT,
	@is_incasso = @is_incasso OUTPUT,
	@auto_acc_num_template = @auto_acc_num_template OUTPUT,
	@auto_acc_num_min_value = @auto_acc_num_min_value OUTPUT

IF @@ERROR <> 0 OR @r <> 0 RETURN 1

IF @account IS NULL
BEGIN
	SET @account = @auto_acc_num_min_value 

	EXEC @r = dbo.GET_NEXT_ACC_NUM_NEW
		@bal_acc = @bal_acc_alt,
		@branch_id = @dept_no,
		@client_no = @client_no,
		@iso = @iso, 
		@product_no = @product_no,
		@template = @auto_acc_num_template,
		@acc = @account OUTPUT,
		@user_id = @user_id,
		@return_row = 0
	IF @@ERROR <> 0 OR @r <> 0 RETURN 99
END

DECLARE @branch_id int
SET @branch_id = dbo.dept_branch_id (@dept_no)

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

INSERT INTO dbo.ACCOUNTS (
	ACCOUNT,
	ISO,
	BAL_ACC_ALT,
	ACT_PAS,
	REC_STATE,
	DESCRIP,
	DESCRIP_LAT,
	ACC_TYPE,
	ACC_SUBTYPE,
	CLIENT_NO,
	BRANCH_ID,
	DEPT_NO,
	DATE_OPEN,
	PERIOD,
	DATE_CLOSE,
	TARIFF,
	PRODUCT_NO,
	MIN_AMOUNT,
	MIN_AMOUNT_NEW,
	MIN_AMOUNT_CHECK_DATE,
	MIN_AMOUNT_CHECK_DATE_NEW,
	BLOCKED_AMOUNT,
	BLOCK_CHECK_DATE,
	PROF_LOSS_ACC,
	FLAGS,
	REMARK,
	CODE_PHRASE,
	BAL_ACC_OLD,
	RESPONSIBLE_USER_ID,
	IS_CONTROL,
	IS_INCASSO,
	USER_DEF_TYPE,
	BAL_ACC2,
	BAL_ACC3
)
VALUES 
(
	@account,
	@iso,
	@bal_acc_alt,
	@act_pas,
	@rec_state,
	@descrip,
	@descrip_lat,
	@acc_type, 
	@acc_subtype,
	@client_no,
	@branch_id,
	@dept_no,
	@date_open,
	@period,
	@date_close,
	@tariff,
	@product_no,
	@min_amount,
	@min_amount_new,
	@min_amount_check_date,
	@min_amount_check_date_new,
	@blocked_amount,
	@block_check_date,
	@prof_loss_acc,
	@flags,
	@remark,
	@code_phrase,
	@bal_acc_old,
	@responsible_user_id,
	@is_control,
	@is_incasso,
	@user_def_type,
	@bal_acc2,
	@bal_acc3
)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

SET @acc_id	= SCOPE_IDENTITY()

INSERT INTO dbo.ACCOUNTS_DETAILS (ACC_ID)
VALUES (@acc_id)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

INSERT INTO dbo.ACC_CHANGES (ACC_ID, [USER_ID], DESCRIP)
VALUES (@acc_id, @user_id, 'ÀÍÂÀÒÉÛÉÓ ÃÀÌÀÔÄÁÀ')
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

IF @client_no IS NOT NULL
BEGIN
	UPDATE dbo.CLIENTS
	SET CLIENT_TYPE_BANK = CLIENT_TYPE_BANK | 0x01
	WHERE CLIENT_NO = @client_no AND CLIENT_TYPE_BANK & 0x01 = 0

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
