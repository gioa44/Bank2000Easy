SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[fp_add_doc_send]
	@rec_id int OUTPUT,
	@user_id int, 
	@dept_no int, 
	@fp_sys_id int, 
	@doc_date smalldatetime,
	@amount money, 
	@iso char(3), 
	@co char(2), 
	@fee1 money, 
	@fee2 money,
	
	@first_name varchar(50) = null,
	@last_name varchar(50) = null, 
	@fathers_name varchar(50) = null, 
	@birth_date smalldatetime = null, 
	@birth_place varchar(100) = null, 
	@address_jur varchar(100) = null, 
	@address_lat varchar(100) = null,
	@country varchar(2) = null, 
	@passport_type_id tinyint = 0, 
	@passport varchar(50) = null, 
	@personal_id varchar(20) = null,
	@reg_organ varchar(50) = null,
	@passport_issue_dt smalldatetime = null,
	@passport_end_date smalldatetime = null
AS

SET NOCOUNT ON;

DECLARE
	@use_head_branch_accounts bit,
	@transit_acc TACCOUNT,
	@profit_acc TACCOUNT,
	@transit_acc_id int,
	@profit_acc_id int
	
DECLARE 
	@r int,
	@rec_id2 int,
	@head_branch_id int,
	@branch_id int,
	@kas_acc TACCOUNT,
	@kas_acc_id int,
	@amount1 money,
	@amount2 money,
	@op_code TOPCODE,
	@descrip varchar(150),
	@alias varchar(50)

SET @branch_id = dbo.dept_branch_id(@dept_no)

IF @iso <> 'GEL'
	EXEC @r = dbo.GET_DEPT_ACC @dept_no, 'KAS_ACC_V', @kas_acc OUTPUT
ELSE
	EXEC @r = dbo.GET_DEPT_ACC @dept_no, 'KAS_ACC', @kas_acc OUTPUT
IF @@ERROR <> 0 OR @r <> 0 RETURN 1
	
SET @kas_acc_id = dbo.acc_get_acc_id(@branch_id, @kas_acc, @iso);
IF @kas_acc_id IS NULL
BEGIN
	RAISERROR ('<ERR>Cannot find cash desk account</ERR>', 16, 1)
	RETURN 1
END

SELECT @use_head_branch_accounts = USE_HEAD_BRANCH_ACCOUNTS, @transit_acc = TRANSIT_ACC_SEND, @profit_acc = PROFIT_ACC_SEND, @alias = ALIAS
FROM dbo.FAST_PAYMENT_SYSTEMS (NOLOCK)
WHERE FP_SYS_ID = @fp_sys_id

IF @transit_acc IS NULL
BEGIN
	RAISERROR ('<ERR>Transit account is empty</ERR>', 16, 1)
	RETURN 1
END

IF @use_head_branch_accounts = 1 
	SET @head_branch_id = dbo.bank_head_branch_id()

SET @transit_acc_id = dbo.acc_get_acc_id(CASE WHEN @use_head_branch_accounts = 1 THEN @head_branch_id ELSE @branch_id END, @transit_acc, @iso);
IF @transit_acc_id IS NULL
BEGIN
	RAISERROR ('<ERR>Cannot find transit account</ERR>', 16, 1)
	RETURN 1
END

SET @profit_acc_id = dbo.acc_get_acc_id(@branch_id, @profit_acc, @iso);
IF @profit_acc_id IS NULL
BEGIN
	RAISERROR ('<ERR>Cannot find profit account</ERR>', 16, 1)
	RETURN 1
END

SET @op_code = 'F+' + @co

IF @fp_sys_id = 1 -- WU
BEGIN
	SET @amount1 = @amount + ISNULL(@fee1, $0.00) + ISNULL(@fee2, $0.00)
	SET @amount2 = ISNULL(@fee1, $0.00) + ISNULL(@fee2, $0.00)
END
ELSE
IF @fp_sys_id = 2 -- Contact
BEGIN
	SET @amount1 = @amount + ISNULL(@fee1, $0.00)
	SET @amount2 = ISNULL(@fee2, $0.00)
END
ELSE
IF @fp_sys_id = 3 -- Unistream
BEGIN
	SET @amount1 = @amount + ISNULL(@fee1, $0.00)
	SET @amount2 = ISNULL(@fee2, $0.00)
END

DECLARE @par_rec_id int
IF @amount2 > $0.00
	SET @par_rec_id = -1
ELSE
	SET @par_rec_id = 0


DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

SET @descrip = @alias + ' ÓÉÓÔÄÌÉÈ ÈÀÍáÉÓ ÂÀÃÀÒÉÝáÅÀ'

EXEC @r = dbo.ADD_DOC4
   @rec_id = @rec_id OUTPUT
  ,@user_id = @user_id
  ,@owner = @user_id
  ,@doc_type = 120
  ,@doc_date = @doc_date
  ,@doc_date_in_doc = @doc_date
  ,@debit_id = @kas_acc_id
  ,@credit_id = @transit_acc_id
  ,@iso = @iso
  ,@amount = @amount1
  ,@rec_state = 0
  ,@descrip = @descrip 
  ,@op_code = @op_code
  ,@dept_no = @dept_no
  ,@foreign_id = @fp_sys_id
  ,@channel_id = 0
  ,@parent_rec_id = @par_rec_id
  ,@first_name = @first_name
  ,@last_name = @last_name
  ,@fathers_name = @fathers_name
  ,@birth_date = @birth_date
  ,@birth_place = @birth_place
  ,@address_jur = @address_jur
  ,@address_lat = @address_lat
  ,@country = @country
  ,@passport_type_id = @passport_type_id
  ,@passport = @passport
  ,@personal_id = @personal_id
  ,@reg_organ = @reg_organ
  ,@passport_issue_dt = @passport_issue_dt
  ,@passport_end_date = @passport_end_date
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@check_limits = 0
  ,@info = 0
  ,@lat = 0
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END  

IF @amount2 > $0.00
BEGIN
	SET @descrip = @alias + ' ÓÉÓÔÄÌÉÈ ÈÀÍáÉÓ ÂÀÃÀÒÉÝáÅÉÓ ÓÀÊÏÌÉÓÉÏ'

	EXEC @r = dbo.ADD_DOC4
	   @rec_id = @rec_id2 OUTPUT
	  ,@user_id = @user_id
	  ,@owner = @user_id
	  ,@doc_type = 99
	  ,@doc_date = @doc_date
	  ,@doc_date_in_doc = @doc_date
	  ,@debit_id = @transit_acc_id
	  ,@credit_id = @profit_acc_id
	  ,@iso = @iso
	  ,@amount = @amount2
	  ,@rec_state = 0
	  ,@descrip = @descrip
	  ,@op_code = @op_code
	  ,@dept_no = @dept_no
	  ,@foreign_id = @fp_sys_id
	  ,@channel_id = 0
	  ,@parent_rec_id = @rec_id
	  ,@check_saldo = 0
	  ,@add_tariff = 0
	  ,@check_limits = 0
	  ,@info = 0
	  ,@lat = 0
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END  
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
