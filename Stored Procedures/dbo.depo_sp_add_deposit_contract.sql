SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_add_deposit_contract]
	@depo_id int OUTPUT,
	@user_id int,
	@branch_id int,
	@dept_no int,
	@client_no int,
	@trust_deposit bit = NULL,
	@trust_client_no int = NULL,
	@trust_extra_info varchar(255) = NULL,
	@prod_id int,
	@iso TISO,
	@agreement_amount money = NULL,
	@period int = NULL,
	@start_date smalldatetime,
	@end_date smalldatetime = NULL,
	@intrate money,

	@depo_realize_schema_amount money = NULL, 

	@convertible bit, 
	@prolongable bit,

	@shareable bit,
	@shared_control_client_no int = NULL,
	@shared_control bit,

	@child_control_client_no_1 int = NULL,
	@child_control_client_no_2 int = NULL,

	@depo_fill_acc_id int = NULL,
	@depo_realize_acc_id int = NULL,
	@interest_realize_type tinyint,
	@interest_realize_acc_id int = NULL,

	@interest_realize_adv bit,
	@interest_realize_adv_amount money = NULL,

	@accumulative bit,
	@accumulate_product bit,
	@accumulate_amount money = NULL,

	@renewable bit,
	@renew_capitalized bit,
	@renew_max int = NULL,

	@spend bit,
	@spend_intrate money = NULL,
	@spend_amount money  = NULL,

	@depo_acc_id int = NULL, --ანაბრის ანგარიში
	@loss_acc_id int = NULL, --ხარჯის ანგარიში
	@accrual_acc_id int = NULL, --დაგროვების ანგარიში
	@interest_realize_adv_acc_id int = NULL, --სატრანზიტო ანგარიში სარგებლის წინასწარი რეალიზაციის დროს
	@depo_note varchar(255) = NULL,
	@editing bit = 0
AS

SET NOCOUNT ON;

DECLARE
	@e int,
	@r int

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE -- Deposit Data
	@state tinyint,
	@alarm_state tinyint,
	@agreement_no varchar(100),
	@amount money,
	@real_intrate money,
	@annulment_date smalldatetime,
	@formula varchar(255),
	@realize_type tinyint,
	@realize_count smallint,
	@realize_count_type tinyint,
	@spend_const_amount money

DECLARE -- Product Data
	@code TCODE,
	@prod_no int,
	@agr_no_template varchar(255),
	@depo_type tinyint,
	@depo_acc_subtype int,
	@depo_account_state tinyint,
	@date_type tinyint,
	@perc_flags int,
	@days_in_year int,
	@intrate_schema int,
	@accrue_type tinyint,
	@recalculate_type tinyint,
	@realize_schema int,
	@depo_realize_schema int,
	@renew_last_prod_id int,
	@revision_schema int,
	@revision_type tinyint,
	@revision_count smallint,
	@revision_count_type tinyint,
	@revision_grace_items int,
	@revision_grace_date_type tinyint,
	@annulmented bit,
	@annulment_realize bit,
	@annulment_schema int,
	@annulment_schema_advance int,
	@child_deposit bit,
	@accumulate_min money,
	@accumulate_max money,
	@accumulate_max_amount money,
	@accumulate_max_amount_limit money,
	@accumulate_schema_intrate int,
	@accrue_amount_min money,
	@accrue_amount_max money,
	@spend_min money,
	@spend_max money,
	@spend_amount_intrate money,
	@depo_acc_templ varchar(150),
	@loss_acc_templ varchar(150),
	@accrual_acc_templ varchar(150),
	@depo_realize_type tinyint,
	@creditcard_balance_check bit,
	@interest_adv_realize_acc_templ varchar(150),
	@depo_fill_accounts tinyint

DECLARE	--init data
	@user_id_init int,
	@period_init int,
	@start_date_init smalldatetime,
	@end_date_init smalldatetime,
	@shareable_init bit,
	@shared_control_client_no_init int,
	@shared_control_init bit,
	@child_deposit_init bit,
	@child_control_client_no_1_init int,
	@child_control_client_no_2_init int,
	@spend_init bit,
	@spend_intrate_init money,
	@spend_amount_init money,
	@update_sql nvarchar(1000),
	@acc_changes varchar(1000),
	@rec_id int


DECLARE
	@depo_bal_acc TBAL_ACC,
	@bal_acc TBAL_ACC,
	@account TACCOUNT,
	@rec_state tinyint,
	@client_type tinyint,
	@descrip varchar(150),
	@descrip_lat varchar(150),
	@acc_product_no int,
	@acc_open_date smalldatetime,
	@acc_period smalldatetime,
	@min_amount money,
	@min_amount_new money,
	@min_amount_check_date smalldatetime,
	@remark varchar(100)

DECLARE
	@common_branch_id int,
	@acc_branch_id int,
	@acc_dept_no int

SET @common_branch_id = dbo.depo_common_branch_id()


SELECT @code = CODE, @prod_no = PROD_NO, @agr_no_template = AGR_NO_TEMPLATE, @depo_type = DEPO_TYPE, @depo_acc_subtype = DEPO_ACC_SUBTYPE, @depo_account_state = DEPO_ACCOUNT_STATE,
	@date_type = DATE_TYPE, @perc_flags = PERC_FLAGS, @days_in_year = DAYS_IN_YEAR, @intrate_schema = INTRATE_SCHEMA, @accrue_type = ACCRUE_TYPE, @recalculate_type = RECALCULATE_TYPE, @realize_schema = REALIZE_SCHEMA,
	@depo_realize_schema = DEPO_REALIZE_SCHEMA, @renew_last_prod_id = RENEW_LAST_PROD_ID, 
	@revision_schema = REVISION_SCHEMA, @revision_grace_items = REVISION_GRACE_ITEMS, @revision_grace_date_type = REVISION_GRACE_DATE_TYPE,
	@annulmented = ANNULMENTED, @annulment_realize = ANNULMENT_REALIZE, @annulment_schema = ANNULMENT_SCHEMA, @annulment_schema_advance = ANNULMENT_SCHEMA_ADVANCE, @child_deposit = CHILD_DEPOSIT,
	@accumulate_schema_intrate = ACCUMULATE_SCHEMA_INTRATE,
	@depo_acc_templ = DEPO_ACC_TEMPL, @loss_acc_templ = LOSS_ACC_TEMPL, @accrual_acc_templ = ACCRUAL_ACC_TEMPL,
	@depo_realize_type = DEPO_REALIZE_TYPE,	@creditcard_balance_check = CREDITCARD_BALANCE_CHECK, @interest_adv_realize_acc_templ = INTEREST_ADV_REALIZE_ACC_TEMPL,
	@depo_fill_accounts = DEPO_FILL_ACCOUNTS
FROM dbo.DEPO_PRODUCT (NOLOCK)
WHERE PROD_ID = @prod_id

SELECT @accumulate_min = ACCUMULATE_MIN, @accumulate_max = ACCUMULATE_MAX, @accumulate_max_amount = ACCUMULATE_AMOUNT, @accumulate_max_amount_limit = ACCUMULATE_AMOUNT_LIMIT,
	@accrue_amount_min = ACCRUE_AMOUNT_MIN, @accrue_amount_max = ACCRUE_AMOUNT_MAX, @spend_min = SPEND_MAX, @spend_max = SPEND_MAX,
	@spend_amount_intrate = SPEND_INTRATE
FROM dbo.DEPO_PRODUCT_PROPERTIES (NOLOCK)
WHERE PROD_ID = @prod_id AND ISO = @iso

SELECT @revision_type = REVISION_TYPE, @revision_count = REVISION_COUNT, @revision_count_type = REVISION_COUNT_TYPE
FROM dbo.DEPO_PRODUCT_REVISION_SCHEMA (NOLOCK)
WHERE [SCHEMA_ID] = @revision_schema

SET @state = 40
SET @real_intrate = @intrate
SET @alarm_state = 0
SET @amount = ISNULL(@agreement_amount, $0.00)
SET @annulment_date = NULL

IF @editing = 0
BEGIN
	EXEC @r = dbo.depo_sp_get_depo_agreement_no
		@agreement_no = @agreement_no OUTPUT,
		@template = @agr_no_template,
		@date = @start_date,
		@client_no = @client_no,
		@dept_no = @dept_no,
		@ccy = @iso,
		@prod_id = @prod_id
	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE AGREEMENT NO', 16, 1); RETURN (1); END
END
ELSE
BEGIN
	SELECT @agreement_no = AGREEMENT_NO
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id	
END

SELECT @realize_type = REALIZE_TYPE, @realize_count = REALIZE_COUNT, @realize_count_type = REALIZE_COUNT_TYPE
FROM dbo.DEPO_PRODUCT_REALIZE_SCHEMA (NOLOCK)
WHERE [SCHEMA_ID] = @realize_schema

IF @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING REALIZE DATA', 16, 1); RETURN (1); END


SET @remark = ''
IF @depo_acc_id IS NULL
BEGIN

	SET @bal_acc = NULL

	EXEC @r = dbo.depo_sp_get_depo_bal_acc
		@bal_acc = @bal_acc OUTPUT,
		@client_no = @client_no,
		@prod_id = @prod_id,
		@iso = @iso,
		@depo_type = @depo_type

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END

	SET @depo_bal_acc = @bal_acc


	IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÐÒÏÃÖØÔÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN(1); END

	EXEC dbo.depo_sp_generate_account
		@account = @account OUTPUT,  
		@template = @depo_acc_templ,
		@branch_id = @branch_id,
		@dept_id = @dept_no,
		@bal_acc = @bal_acc,  
		@depo_bal_acc = @bal_acc,
		@client_no = @client_no, 
		@ccy = @iso, 
		@prod_code4	= @prod_no

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT ACCOUNT', 16, 1); RETURN (1); END

	SELECT @client_type = CLIENT_TYPE, @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1) RETURN (1) END

	IF @shareable = 1
	BEGIN
		SELECT @descrip = @descrip + ' (' + DESCRIP + ')', @descrip_lat = @descrip_lat + ' (' + DESCRIP_LAT + ')'
		FROM dbo.CLIENTS (NOLOCK)
		WHERE CLIENT_NO = @shared_control_client_no
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END

		IF @shared_control = 1
			SET @remark = 'ÄÒÈÏÁËÉÅÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'
		ELSE
			SET @remark = 'ÃÀÌÏÖÊÉÃÄÁÄËÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'
	END

	IF @child_deposit = 1
	BEGIN
		SELECT @remark = @remark + ' (' + DESCRIP
		FROM dbo.CLIENTS (NOLOCK)
		WHERE CLIENT_NO = @child_control_client_no_1
		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END

		IF @child_control_client_no_2 IS NOT NULL
		BEGIN
			SELECT @remark = @remark + ', ' + DESCRIP
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @child_control_client_no_2
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END
		END

		SET @remark = @remark + ') '
	END 

	SET @rec_state = CASE @depo_account_state
		WHEN 1 THEN 1
		WHEN 2 THEN 4
		WHEN 3 THEN 16
	END

	SET @acc_product_no = @prod_no
	SET @acc_open_date = @start_date
	SET	@acc_period = @end_date

	EXEC @r = dbo.on_user_depo_sp_add_deposit_account
		@prod_id = @prod_id,
		@client_no = @client_no,
		@descrip = @descrip OUTPUT,
		@descrip_lat = @descrip_lat OUTPUT,
		@date_open = @acc_open_date OUTPUT,
		@period = @acc_period OUTPUT,
		@product_no = @acc_product_no OUTPUT
	IF @r <> 0 OR @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1); RETURN (1); END

	IF @acc_product_no IS NOT NULL
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

		IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
	END

	IF NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÐÒÏÃÖØÔÉÓ ÛÄÓÀÁÀÌÉÓÉ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ (ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN(1); END

	IF ISNULL(@spend_amount, $0.00) <> $0.00
	BEGIN
		SET @min_amount =  @spend_amount
		SET @min_amount_new = @spend_amount
		SET @min_amount_check_date = @end_date
	END
	ELSE
	BEGIN
		SET @min_amount = $0.00
		SET @min_amount_new = $0.00
		SET @min_amount_check_date = NULL
	END

	EXEC @r = dbo.ADD_ACCOUNT
		@acc_id = @depo_acc_id OUTPUT,
		@user_id = @user_id,
		@dept_no = @dept_no,
		@account = @account,
		@iso = @iso,
		@bal_acc_alt = @bal_acc,
		@rec_state = @rec_state,
		@descrip = @descrip,
		@descrip_lat = @descrip_lat,
		@acc_type = 32,
		@acc_subtype = @depo_acc_subtype,
		@client_no = @client_no,
		@date_open = @acc_open_date,
		@period = @acc_period,
		@product_no = @acc_product_no,
		@min_amount = @min_amount,
		@min_amount_new = @min_amount_new,
		@min_amount_check_date = @min_amount_check_date,
		@remark = @remark
	IF @r <> 0 OR @@ERROR<>0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1); RETURN (1); END
END
ELSE
BEGIN

	SET	@update_sql = ''
	SET @acc_changes = ''

	IF @editing = 1
	BEGIN
		SELECT 	@start_date_init = [START_DATE],
				@end_date_init = END_DATE, 			
				@shareable_init = SHAREABLE,
				@shared_control_client_no_init = SHARED_CONTROL_CLIENT_NO, 
				@shared_control_init = SHARED_CONTROL,
				@child_deposit_init = CHILD_DEPOSIT,
				@child_control_client_no_1_init = CHILD_CONTROL_CLIENT_NO_1, 
				@child_control_client_no_2_init = CHILD_CONTROL_CLIENT_NO_2,											
				@spend_amount_init = SPEND_AMOUNT
		FROM dbo.DEPO_DEPOSITS (NOLOCK)
		WHERE DEPO_ID = @depo_id
		
		IF ( ISNULL(@shareable_init, 0) <> ISNULL(@shareable, 0) ) OR ( ISNULL(@shared_control_client_no_init, 0) <> ISNULL(@shared_control_client_no, 0))
		BEGIN
			SELECT @descrip = DESCRIP, @descrip_lat = DESCRIP_LAT
			FROM dbo.CLIENTS (NOLOCK)
			WHERE CLIENT_NO = @client_no
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END
		
			IF @shareable = 1
			BEGIN
				SELECT @descrip = @descrip + ' (' + DESCRIP + ')', @descrip_lat = @descrip_lat + ' (' + DESCRIP_LAT + ')'
				FROM dbo.CLIENTS (NOLOCK)
				WHERE CLIENT_NO = @shared_control_client_no
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END			
			END

			SET @update_sql = @update_sql + 'DESCRIP = @descrip,'
			SET @acc_changes = @acc_changes + ' DESCRIP'
		END
		
		IF ISNULL(@shared_control_init, 0) <> ISNULL(@shared_control, 0)
		BEGIN
			IF @shared_control = 1
				SET @remark = 'ÄÒÈÏÁËÉÅÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'
			ELSE
				SET @remark = 'ÃÀÌÏÖÊÉÃÄÁÄËÉ ÂÀÍÊÀÒÂÅÉÓ Ö×ËÄÁÉÈ'

			SET @update_sql = @update_sql + 'REMARK = @remark,'
			SET @acc_changes = @acc_changes + ' REMARK' 
		END
		
		IF ISNULL(@child_deposit_init, 0) <> ISNULL(@child_deposit, 0)
		BEGIN
			IF @child_deposit = 1
			BEGIN
				SELECT @remark = @remark + ' (' + DESCRIP
				FROM dbo.CLIENTS (NOLOCK)
				WHERE CLIENT_NO = @child_control_client_no_1
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END

				IF @child_control_client_no_2 IS NOT NULL
				BEGIN
					SELECT @remark = @remark + ', ' + DESCRIP
					FROM dbo.CLIENTS (NOLOCK)
					WHERE CLIENT_NO = @child_control_client_no_2
					IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING CLIENT DATA', 16, 1); RETURN (1); END
				END

				SET @remark = @remark + ') '
				SET @update_sql = @update_sql + 'REMARK = @remark,'
				SET @acc_changes = @acc_changes + ' REMARK' 
			END
		END 
		
		IF @start_date_init <> @start_date
		BEGIN
			SET @acc_open_date = @start_date
			SET @update_sql = @update_sql + 'DATE_OPEN = @acc_open_date,'
			SET @acc_changes = @acc_changes + ' DATE_OPEN'
		END 

		IF @end_date_init <> @end_date
		BEGIN
			SET	@acc_period = @end_date
			SET @update_sql = @update_sql + 'PERIOD = @acc_period,'
			SET @acc_changes = @acc_changes + ' PERIOD'
		END 
			

		IF ISNULL(@spend_amount_init, $0.00) <> ISNULL(@spend_amount, $0.00)
		BEGIN
			IF ISNULL(@spend_amount, $0.00) <> $0.00
			BEGIN
				SET @min_amount =  @spend_amount
				SET @min_amount_new = @spend_amount
				SET @min_amount_check_date = @end_date
			END
			ELSE
			BEGIN
				SET @min_amount = $0.00
				SET @min_amount_new = $0.00
				SET @min_amount_check_date = NULL
			END

			SET @update_sql = @update_sql + 'MIN_AMOUNT = @min_amount,'
			SET @acc_changes = @acc_changes + ' MIN_AMOUNT'

			SET @update_sql = @update_sql + 'MIN_AMOUNT_NEW = @min_amount_new,'
			SET @acc_changes = @acc_changes + ' MIN_AMOUNT_NEW'

			SET @update_sql = @update_sql + 'MIN_AMOUNT_CHECK_DATE = @min_amount_check_date,'
			SET @acc_changes = @acc_changes + ' MIN_AMOUNT_CHECK_DATE'

		END 
		
		IF @update_sql <> ''
		BEGIN
			SET @acc_changes = 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ : UID ' + @acc_changes
			INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
			VALUES (@depo_acc_id, @user_id, @acc_changes)
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT LOG', 16, 1); RETURN (1); END

			SET @rec_id = SCOPE_IDENTITY()
			
			INSERT INTO dbo.ACCOUNTS_ARC
			SELECT @rec_id, *
			FROM dbo.ACCOUNTS
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT ARC', 16, 1); RETURN (1); END

			SET @update_sql = 'UPDATE dbo.ACCOUNTS WITH (UPDLOCK) SET ' + LEFT(@update_sql, len(@update_sql)-1)
			SET @update_sql = @update_sql + ' WHERE ACC_ID = @depo_acc_id'
			
			EXEC @r = sp_executesql @update_sql,
				N'@descrip varchar(150), @remark varchar(100), @acc_open_date smalldatetime, @acc_period smalldatetime, @min_amount money, @min_amount_new money, @min_amount_check_date smalldatetime, @depo_acc_id int', 
				@descrip, @remark, @acc_open_date, @acc_period, @min_amount, @min_amount_new, @min_amount_check_date, @depo_acc_id
			IF @@ERROR <> 0 OR @r <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END
					
			UPDATE dbo.ACCOUNTS WITH (UPDLOCK)
			SET [UID] = [UID] + 1
			WHERE ACC_ID = @depo_acc_id
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END

		END
	END 
END 



IF @interest_realize_adv = 1
BEGIN
	IF @interest_realize_adv_acc_id IS NULL
	BEGIN
		SET @bal_acc = NULL

		EXEC @r = dbo.depo_sp_get_depo_realize_adv_bal_acc
			@bal_acc = @bal_acc OUTPUT,
			@depo_bal_acc = @depo_bal_acc,
			@client_no = @client_no,
			@prod_id = @prod_id,
			@iso = @iso,
			@depo_type = @depo_type
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END

		IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
		BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1) RETURN(1) END

		IF (CHARINDEX('N', UPPER(@interest_adv_realize_acc_templ)) = 0) AND (@common_branch_id <> -1)
		BEGIN
			SET @acc_branch_id = @common_branch_id
			SET @acc_dept_no = @common_branch_id
		END
		ELSE
		BEGIN
			SET @acc_branch_id = @branch_id
			SET @acc_dept_no = @dept_no
		END

		EXEC dbo.depo_sp_generate_account
			@account = @account OUTPUT,  
			@template = @interest_adv_realize_acc_templ,
			@branch_id = @acc_branch_id,
			@dept_id = @acc_dept_no,
			@bal_acc = @bal_acc,  
			@depo_bal_acc = @depo_bal_acc,
			@client_no = @client_no, 
			@ccy = @iso, 
			@prod_code4	= @prod_no

		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT REALIZE ADV ACCOUNT', 16, 1); RETURN (1); END

		IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @acc_branch_id AND ACCOUNT = @account AND ISO = @iso)
		BEGIN
			IF CHARINDEX('N', UPPER(@interest_adv_realize_acc_templ)) = 0
			BEGIN
				IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
				RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ×ÉØÓÉÒÄÁÖËÉ ÀÍÂÀÒÉÛÉ', 16, 1);
				RETURN (1);
			END
			
			SELECT @descrip = 'ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ', @descrip_lat = 'Account 25X1 (INTEREST REALIZE ADVANCE)'

			SET @acc_product_no = NULL
			SET @acc_open_date = @start_date
			SET	@acc_period = @end_date

			EXEC @r = dbo.on_user_depo_sp_add_deposit_realize_adv_account
				@prod_id = @prod_id,
				@client_no = @client_no,
				@descrip = @descrip OUTPUT,
				@descrip_lat = @descrip_lat OUTPUT,
				@date_open = @acc_open_date OUTPUT,
				@period = @acc_period OUTPUT,
				@product_no = @acc_product_no OUTPUT
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1); RETURN (1); END

			IF @acc_product_no IS NOT NULL
			BEGIN
				IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
				BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

				IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
				BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
			END

			EXEC @r = dbo.ADD_ACCOUNT
				@acc_id = @interest_realize_adv_acc_id OUTPUT,
				@user_id = @user_id,
				@dept_no = @acc_dept_no,
				@account = @account,
				@iso = @iso,
				@bal_acc_alt = @bal_acc,
				@rec_state = 1,
				@descrip = @descrip,
				@descrip_lat = @descrip_lat,
				@acc_type = 1,
				@acc_subtype = NULL,
				@client_no = @client_no,
				@date_open = @acc_open_date,
				@period = @acc_period,
				@product_no = @acc_product_no
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1) RETURN (1) END
		END
		ELSE
			SET @interest_realize_adv_acc_id = dbo.acc_get_acc_id (@acc_branch_id, @account, @iso)
	END
	ELSE
	BEGIN
		SET	@update_sql = ''
		SET @acc_changes = ''

		IF @editing = 1
		BEGIN
			SELECT 	@start_date_init = [START_DATE],
					@end_date_init = END_DATE
			FROM dbo.DEPO_DEPOSITS (NOLOCK)
			WHERE DEPO_ID = @depo_id
					
			IF @start_date_init <> @start_date
			BEGIN
				SET @acc_open_date = @start_date
				SET @update_sql = @update_sql + 'DATE_OPEN = @acc_open_date,'
				SET @acc_changes = @acc_changes + ' DATE_OPEN'
			END 

			IF @end_date_init <> @end_date
			BEGIN
				SET	@acc_period = @end_date
				SET @update_sql = @update_sql + 'PERIOD = @acc_period,'
				SET @acc_changes = @acc_changes + ' PERIOD'
			END 
						
			IF @update_sql <> ''
			BEGIN
				SET @update_sql = 'UPDATE dbo.ACCOUNTS SET ' + LEFT(@update_sql, len(@update_sql)-1)
				SET @update_sql = @update_sql + ' WHERE ACC_ID = @interest_realize_adv_acc_id'
				
				EXEC @r = sp_executesql @update_sql,
					N'@acc_open_date smalldatetime, @acc_period smalldatetime, @interest_realize_adv_acc_id int', 
					@acc_open_date, @acc_period, @interest_realize_adv_acc_id
				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END
				
				SET @acc_changes = 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ :' + @acc_changes
				INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
				VALUES (@interest_realize_adv_acc_id, @user_id, @acc_changes)
				IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT ACCOUNT LOG', 16, 1); RETURN (1); END
			END
		END 
	END
END
ELSE
BEGIN
	DECLARE @interest_realize_adv_acc_id_init int

	SELECT @interest_realize_adv_acc_id_init = INTEREST_REALIZE_ADV_ACC_ID
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id

	IF @interest_realize_adv_acc_id_init IS NOT NULL
	BEGIN
		UPDATE dbo.DEPO_DEPOSITS WITH (UPDLOCK)
		SET INTEREST_REALIZE_ADV_ACC_ID = NULL
		WHERE DEPO_ID = @depo_id

		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR EDITING DEPOSIT DATA!', 16, 1); RETURN (1); END

	
		DECLARE
			@dt smalldatetime,
			@shadow_level smallint,
			@saldo money,
			@saldo_equ money,
			@acc_client_no int

		SET @acc_client_no = NULL
		SELECT @acc_client_no = CLIENT_NO
		FROM dbo.ACCOUNTS (NOLOCK)
		WHERE ACC_ID = @interest_realize_adv_acc_id

		IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETING ACCOUNT DATA!', 16, 1); RETURN (1); END

		IF @acc_client_no IS NOT NULL
		BEGIN
			EXEC @r = dbo.GET_ACC_SALDO4
				@acc_id = @interest_realize_adv_acc_id,
				@dt = @dt,
				@shadow_level = @shadow_level,
				@saldo = @saldo OUTPUT,
				@saldo_equ = @saldo_equ OUTPUT

			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETING ACCOUNT SALDO!', 16, 1); RETURN (1); END

			IF ISNULL(@saldo, $0.00) <> $0.00 OR ISNULL(@saldo_equ, $0.00) <> $0.00
			BEGIN
				IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÒÂÄÁËÉÓ ßÉÍÀÓßÀÒÉ ÒÄÀËÉÆÀÝÉÉÓ ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÆÄ ÀÒÉÓ ÀÒÀÍÖËÏÅÀÍÉ ÍÀÛÈÉ, ÀÍÂÀÒÉÛÉÓ ßÀÛËÀ ÛÄÖÞËÄÁÄËÉÀ!', 16, 1);
				RETURN (1);
			END

			DELETE FROM dbo.ACCOUNTS
			WHERE ACC_ID = @interest_realize_adv_acc_id

			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR DELETING ACCOUNT (INTEREST ADV)!', 16, 1); RETURN (1); END

			SET @interest_realize_adv_acc_id = NULL
		END
	END 

END


IF @loss_acc_id IS NULL
BEGIN

	SET @bal_acc = NULL

	EXEC @r = dbo.depo_sp_get_depo_loss_bal_acc
		@bal_acc = @bal_acc OUTPUT,
		@depo_bal_acc = @depo_bal_acc,
		@client_no = @client_no,
		@prod_id = @prod_id,
		@iso = @iso,
		@depo_type = @depo_type

	IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END

	IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN(1); END

	IF (CHARINDEX('N', UPPER(@loss_acc_templ)) = 0) AND (@common_branch_id <> -1)
	BEGIN
		SET @acc_branch_id = @common_branch_id
		SET @acc_dept_no = @common_branch_id
	END
	ELSE
	BEGIN
		SET @acc_branch_id = @branch_id
		SET @acc_dept_no = @dept_no
	END


	EXEC dbo.depo_sp_generate_account
		@account = @account OUTPUT,  
		@template = @loss_acc_templ,
		@branch_id = @acc_branch_id,
		@dept_id = @acc_dept_no,
		@bal_acc = @bal_acc,  
		@depo_bal_acc = @depo_bal_acc,
		@client_no = @client_no, 
		@ccy = @iso, 
		@prod_code4	= @prod_no

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT LOSS ACCOUNT', 16, 1); RETURN (1); END

	IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @acc_branch_id AND ACCOUNT = @account AND ISO = @iso)
	BEGIN
		IF CHARINDEX('N', UPPER(@loss_acc_templ)) = 0
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÐÒÏÝÄÍÔÖËÉ áÀÒãÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ ×ÉØÓÉÒÄÁÖËÉ ÀÍÂÀÒÉÛÉ', 16, 1);
			RETURN (1);
		END
	
		SELECT @descrip = 'ÐÒÏÝÄÍÔÖËÉ áÀÒãÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ', @descrip_lat = 'Account 83 (LOSS)'

		SET @acc_product_no = NULL
		SET @acc_open_date = @start_date
		SET	@acc_period = @end_date

		EXEC @r = dbo.on_user_depo_sp_add_deposit_loss_account
			@prod_id = @prod_id,
			@client_no = @client_no,
			@descrip = @descrip OUTPUT,
			@descrip_lat = @descrip_lat OUTPUT,
			@date_open = @acc_open_date OUTPUT,
			@period = @acc_period OUTPUT,
			@product_no = @acc_product_no OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1); RETURN (1); END

		IF @acc_product_no IS NOT NULL
		BEGIN
			IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

			IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
		END

		EXEC @r = dbo.ADD_ACCOUNT
			@acc_id = @loss_acc_id OUTPUT,
			@user_id = @user_id,
			@dept_no = @acc_dept_no,
			@account = @account,
			@iso = @iso,
			@bal_acc_alt = @bal_acc,
			@rec_state = 1,
			@descrip = @descrip,
			@descrip_lat = @descrip_lat,
			@acc_type = 1,
			@acc_subtype = NULL,
			@client_no = @client_no,
			@date_open = @acc_open_date,
			@period = @acc_period,
			@product_no = @acc_product_no
		IF @@ERROR <> 0 AND @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ áÀÒãÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1); RETURN (1); END
	END
	ELSE
		SET @loss_acc_id = dbo.acc_get_acc_id (@acc_branch_id, @account, @iso)
END
ELSE
BEGIN
	SET	@update_sql = ''
	SET @acc_changes = ''

	IF @editing = 1
	BEGIN
		SELECT 	@start_date_init = [START_DATE],
				@end_date_init = END_DATE
		FROM dbo.DEPO_DEPOSITS (NOLOCK)
		WHERE DEPO_ID = @depo_id
				
		IF @start_date_init <> @start_date
		BEGIN
			SET @acc_open_date = @start_date
			SET @update_sql = @update_sql + 'DATE_OPEN = @acc_open_date,'
			SET @acc_changes = @acc_changes + ' DATE_OPEN'
		END 

		IF @end_date_init <> @end_date
		BEGIN
			SET	@acc_period = @end_date
			SET @update_sql = @update_sql + 'PERIOD = @acc_period,'
			SET @acc_changes = @acc_changes + ' PERIOD'
		END 
					
		IF @update_sql <> ''
		BEGIN
			SET @update_sql = 'UPDATE dbo.ACCOUNTS SET ' + LEFT(@update_sql, len(@update_sql)-1)
			SET @update_sql = @update_sql + ' WHERE ACC_ID = @loss_acc_id'
			
			EXEC @r = sp_executesql @update_sql,
				N'@acc_open_date smalldatetime, @acc_period smalldatetime, @loss_acc_id int', 
				@acc_open_date, @acc_period, @loss_acc_id
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END
			
			SET @acc_changes = 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ :' + @acc_changes
			INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
			VALUES (@loss_acc_id, @user_id, @acc_changes)
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT ACCOUNT LOG', 16, 1); RETURN (1); END
		END
	END 
END


IF @accrual_acc_id IS NULL
BEGIN
	SET @bal_acc = NULL

	EXEC @r = dbo.depo_sp_get_depo_accrual_bal_acc
		@bal_acc = @bal_acc OUTPUT,
		@depo_bal_acc = @depo_bal_acc,
		@client_no = @client_no,
		@prod_id = @prod_id,
		@iso = @iso,
		@depo_type = @depo_type

	IF @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GETTING BALANCE ACCOUNT', 16, 1); RETURN (1); END

	IF (@bal_acc IS NULL) OR NOT EXISTS(SELECT * FROM dbo.PLANLIST_ALT (NOLOCK) WHERE BAL_ACC = @bal_acc)
	BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÃÄÐÏÆÉÔÉÓ ÃÀÂÒÏÅÄÁÉÓ ÛÄÓÀÁÀÌÉÓÉÓ ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN(1); END

	IF (CHARINDEX('N', UPPER(@accrual_acc_templ)) = 0) AND (@common_branch_id <> -1)
	BEGIN
		SET @acc_branch_id = @common_branch_id
		SET @acc_dept_no = @common_branch_id
	END
	ELSE
	BEGIN
		SET @acc_branch_id = @branch_id
		SET @acc_dept_no = @dept_no
	END

	EXEC dbo.depo_sp_generate_account
		@account = @account OUTPUT,  
		@template = @accrual_acc_templ,
		@branch_id = @acc_branch_id,
		@dept_id = @acc_dept_no,
		@bal_acc = @bal_acc,  
		@depo_bal_acc = @depo_bal_acc,
		@client_no = @client_no, 
		@ccy = @iso, 
		@prod_code4	= @prod_no

	IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE DEPOSIT ACCRUAL ACCOUNT', 16, 1); RETURN (1); END

	IF NOT EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE BRANCH_ID = @acc_branch_id AND ACCOUNT = @account AND ISO = @iso)
	BEGIN
		IF CHARINDEX('N', UPPER(@accrual_acc_templ)) = 0
		BEGIN
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK;
			RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÂÀÃÀÓÀáÃÄËÉ ÐÒÏÝÄÍÔÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ ×ÉØÓÉÒÄÁÖËÉ ÀÍÂÀÒÉÛÉ', 16, 1);
			RETURN (1);
		END
	
		SELECT @descrip = 'ÂÀÃÀÓÀáÃÄËÉ ÐÒÏÝÄÍÔÄÁÉ ÃÄÐÏÆÉÔÄÁÉÓ ÌÉáÄÃÅÉÈ', @descrip_lat = 'Account 44 (ACCRUE)'

		SET @acc_product_no = NULL
		SET @acc_open_date = @start_date
		SET	@acc_period = @end_date

		EXEC @r = dbo.on_user_depo_sp_add_deposit_accrual_account
			@prod_id = @prod_id,
			@client_no = @client_no,
			@descrip = @descrip OUTPUT,
			@descrip_lat = @descrip_lat OUTPUT,
			@date_open = @acc_open_date OUTPUT,
			@period = @acc_period OUTPUT,
			@product_no = @acc_product_no OUTPUT
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÃÀÂÒÏÅÄÁÉÓ ÀÍÂÀÒÉÛÆÄ ÐÀÒÀÌÄÔÒÄÁÉÓ ÌÏÞÉÄÁÉÓÀÓ', 16, 1) RETURN (1) END

		IF @acc_product_no IS NOT NULL
		BEGIN
			IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS (NOLOCK) WHERE PRODUCT_NO = @acc_product_no)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÃÀÂÒÏÅÄÁÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END

			IF NOT EXISTS(SELECT * FROM dbo.ACC_PRODUCTS_FILTER (NOLOCK) WHERE BAL_ACC = @bal_acc AND PRODUCT_NO = @acc_product_no)
			BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÓÀÁÀËÀÍÓÏ ÀÍÂÀÒÉÛÉÓ ÐÒÏÃÖØÔÉ ÀÒ ÌÏÉÞÄÁÍÀ (ÃÄÐÏÆÉÔÉÓ ÃÀÂÒÏÅÄÁÉÓ ÀÍÂÀÒÉÛÉ)', 16, 1); RETURN (1); END
		END

		EXEC @r = dbo.ADD_ACCOUNT
			@acc_id = @accrual_acc_id OUTPUT,
			@user_id = @user_id,
			@dept_no = @acc_dept_no,
			@account = @account,
			@iso = @iso,
			@bal_acc_alt = @bal_acc,
			@rec_state = 1,
			@descrip = @descrip,
			@descrip_lat = @descrip_lat,
			@acc_type = 128,
			@acc_subtype = NULL,
			@client_no = @client_no,
			@date_open = @acc_open_date,
			@period = @acc_period,
			@product_no = @acc_product_no
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÛÄÝÃÏÌÀ ÃÄÐÏÆÉÔÉÓ ÃÀÂÒÏÅÄÁÉÓ ÀÍÂÀÒÉÛÉÓ ÂÀáÓÍÉÓÀÓ', 16, 1); RETURN (1); END
	END
	ELSE
		SET @accrual_acc_id = dbo.acc_get_acc_id (@acc_branch_id, @account, @iso)
END
ELSE
BEGIN
	SET	@update_sql = ''
	SET @acc_changes = ''

	IF @editing = 1
	BEGIN
		SELECT 	@start_date_init = [START_DATE],
				@end_date_init = END_DATE
		FROM dbo.DEPO_DEPOSITS (NOLOCK)
		WHERE DEPO_ID = @depo_id
				
		IF @start_date_init <> @start_date
		BEGIN
			SET @acc_open_date = @start_date
			SET @update_sql = @update_sql + 'DATE_OPEN = @acc_open_date,'
			SET @acc_changes = @acc_changes + ' DATE_OPEN'
		END 

		IF @end_date_init <> @end_date
		BEGIN
			SET	@acc_period = @end_date
			SET @update_sql = @update_sql + 'PERIOD = @acc_period,'
			SET @acc_changes = @acc_changes + ' PERIOD'
		END 
					
		IF @update_sql <> ''
		BEGIN
			SET @update_sql = 'UPDATE dbo.ACCOUNTS SET ' + LEFT(@update_sql, len(@update_sql)-1)
			SET @update_sql = @update_sql + ' WHERE ACC_ID = @accrual_acc_id'
			
			EXEC @r = sp_executesql @update_sql,
				N'@acc_open_date smalldatetime, @acc_period smalldatetime, @accrual_acc_id int', 
				@acc_open_date, @acc_period, @accrual_acc_id
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATE ACCOUNT DATA', 16, 1); RETURN (1); END
			
			SET @acc_changes = 'ÀÍÂÀÒÉÛÉÓ ÛÄÝÅËÀ :' + @acc_changes
			INSERT INTO dbo.ACC_CHANGES (ACC_ID,[USER_ID],DESCRIP) 
			VALUES (@accrual_acc_id, @user_id, @acc_changes)
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT ACCOUNT LOG', 16, 1); RETURN (1); END
		END
	END 
END


IF @interest_realize_acc_id IS NULL
BEGIN
	IF @interest_realize_type = 2
		SET @interest_realize_acc_id = @depo_realize_acc_id
	IF @interest_realize_type = 4
		SET @interest_realize_acc_id = @depo_acc_id
END

IF @interest_realize_acc_id IS NULL
BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ÀÒ ÌÏÉÞÄÁÍÀ ÓÀÒÂÄÁËÉÓ ÒÄÀËÉÆÀÝÉÉÓ ÀÍÂÀÒÉÛÉ', 16, 1); RETURN (1); END

SET @formula = '***NEED FORMULA***'

IF (@spend = 1) AND (ISNULL(@accumulate_schema_intrate, 0) = 4)
	SET @spend_const_amount = @agreement_amount
ELSE
	SET @spend_const_amount = NULL

IF @child_deposit = 1
	SET @trust_extra_info = NULL

IF @editing = 0
BEGIN
	INSERT INTO dbo.DEPO_DEPOSITS WITH (UPDLOCK)
		(BRANCH_ID,  DEPT_NO, [STATE], ALARM_STATE,  CLIENT_NO,  TRUST_DEPOSIT, TRUST_CLIENT_NO, TRUST_EXTRA_INFO,
		PROD_ID,  AGREEMENT_NO,  DEPO_TYPE,  DEPO_ACC_SUBTYPE,  DEPO_ACCOUNT_STATE,  ISO,  AGREEMENT_AMOUNT,  AMOUNT,
		DATE_TYPE,   PERIOD, [START_DATE], END_DATE, ANNULMENT_DATE,  INTRATE, REAL_INTRATE,  PERC_FLAGS,  PROD_ACCRUE_MIN,  PROD_ACCRUE_MAX,  PROD_SPEND_MIN,  PROD_SPEND_MAX,
		FORMULA,  DAYS_IN_YEAR,  INTRATE_SCHEMA,  ACCRUE_TYPE, RECALCULATE_TYPE,
		REALIZE_SCHEMA,  REALIZE_TYPE,  REALIZE_COUNT,  REALIZE_COUNT_TYPE,  DEPO_REALIZE_SCHEMA,  DEPO_REALIZE_SCHEMA_AMOUNT,  CONVERTIBLE,  PROLONGABLE, PROLONGATION_COUNT,
		RENEWABLE,  RENEW_CAPITALIZED,  RENEW_MAX, 	RENEW_LAST_PROD_ID,  SHAREABLE,	SHARED_CONTROL_CLIENT_NO,  SHARED_CONTROL, 	REVISION_SCHEMA,  REVISION_TYPE,  REVISION_COUNT,  REVISION_COUNT_TYPE,  REVISION_GRACE_ITEMS,  REVISION_GRACE_DATE_TYPE,
		ANNULMENTED,  ANNULMENT_REALIZE,  ANNULMENT_SCHEMA,  ANNULMENT_SCHEMA_ADVANCE,  INTEREST_REALIZE_ADV,  INTEREST_REALIZE_ADV_AMOUNT,  CHILD_DEPOSIT, CHILD_CONTROL_OWNER, CHILD_CONTROL_CLIENT_NO_1,  CHILD_CONTROL_CLIENT_NO_2,
		ACCUMULATIVE,  ACCUMULATE_PRODUCT,  ACCUMULATE_AMOUNT, ACCUMULATE_MIN,  ACCUMULATE_MAX, ACCUMULATE_MAX_AMOUNT, ACCUMULATE_MAX_AMOUNT_LIMIT,  ACCUMULATE_SCHEMA_INTRATE,
		SPEND,  SPEND_INTRATE,  SPEND_AMOUNT,  SPEND_AMOUNT_INTRATE,  SPEND_CONST_AMOUNT, DEPO_REALIZE_TYPE, CREDITCARD_BALANCE_CHECK, INTEREST_REALIZE_TYPE,
		DEPO_FILL_ACC_ID,  DEPO_ACC_ID,  LOSS_ACC_ID,  ACCRUAL_ACC_ID,  DEPO_REALIZE_ACC_ID,  INTEREST_REALIZE_ACC_ID,  INTEREST_REALIZE_ADV_ACC_ID,
		RESPONSIBLE_USER_ID, DEPO_NOTE, DEPOSIT_DEFAULT) 
	VALUES																																						 
		(@branch_id, @dept_no, @state, @alarm_state, @client_no, @trust_deposit, @trust_client_no, @trust_extra_info,
		@prod_id, @agreement_no, @depo_type, @depo_acc_subtype, @depo_account_state, @iso, @agreement_amount, @amount,
		@date_type, @period, @start_date, @end_date, @annulment_date, @intrate, @real_intrate, @perc_flags, @accrue_amount_min, @accrue_amount_max, @spend_min, @spend_max,
		@formula, @days_in_year, @intrate_schema, @accrue_type, @recalculate_type,
		@realize_schema, @realize_type, @realize_count, @realize_count_type, @depo_realize_schema, @depo_realize_schema_amount, @convertible, @prolongable, NULL,
		@renewable, @renew_capitalized, @renew_max, @renew_last_prod_id, @shareable,	@shared_control_client_no, @shared_control, @revision_schema, @revision_type, @revision_count, @revision_count_type, @revision_grace_items, @revision_grace_date_type,
		@annulmented, @annulment_realize, @annulment_schema, @annulment_schema_advance, @interest_realize_adv, @interest_realize_adv_amount, @child_deposit, 0,                  @child_control_client_no_1, @child_control_client_no_2,
		@accumulative,  @accumulate_product,  @accumulate_amount, @accumulate_min,  @accumulate_max, @accumulate_max_amount, @accumulate_max_amount_limit, @accumulate_schema_intrate,
		@spend, @spend_intrate, @spend_amount, @spend_amount_intrate, @spend_const_amount, @depo_realize_type, @creditcard_balance_check, @interest_realize_type,
		@depo_fill_acc_id, @depo_acc_id, @loss_acc_id, @accrual_acc_id, @depo_realize_acc_id, @interest_realize_acc_id, @interest_realize_adv_acc_id,
		@user_id, @depo_note, 0)

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT DATA', 16, 1); RETURN (1); END

	SET @depo_id = SCOPE_IDENTITY()
END
ELSE
BEGIN
	DECLARE
		@row_version int

	SELECT @row_version = ROW_VERSION
	FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id

	SET @row_version = @row_version + 1

	DELETE FROM dbo.DEPO_DEPOSITS
	WHERE DEPO_ID = @depo_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR DELETING DEPOSIT', 16, 1); RETURN (1); END	

	SET IDENTITY_INSERT dbo.DEPO_DEPOSITS ON
	INSERT INTO dbo.DEPO_DEPOSITS WITH (UPDLOCK)
		(DEPO_ID, ROW_VERSION,       BRANCH_ID,  DEPT_NO, [STATE], CLIENT_NO, TRUST_DEPOSIT, TRUST_CLIENT_NO, TRUST_EXTRA_INFO,
		PROD_ID,  AGREEMENT_NO,  DEPO_TYPE,  DEPO_ACC_SUBTYPE,  DEPO_ACCOUNT_STATE,  ISO,  AGREEMENT_AMOUNT,  AMOUNT,
		DATE_TYPE,   PERIOD, [START_DATE], END_DATE, ANNULMENT_DATE,  INTRATE, REAL_INTRATE, PERC_FLAGS,  PROD_ACCRUE_MIN,  PROD_ACCRUE_MAX,  PROD_SPEND_MIN,  PROD_SPEND_MAX,
		FORMULA,  DAYS_IN_YEAR,  INTRATE_SCHEMA,  ACCRUE_TYPE, RECALCULATE_TYPE,
		REALIZE_SCHEMA,  REALIZE_TYPE,  REALIZE_COUNT,  REALIZE_COUNT_TYPE,  DEPO_REALIZE_SCHEMA,  DEPO_REALIZE_SCHEMA_AMOUNT,  CONVERTIBLE,  PROLONGABLE, PROLONGATION_COUNT,
		RENEWABLE,  RENEW_CAPITALIZED,  RENEW_MAX, 	RENEW_LAST_PROD_ID,  SHAREABLE,	SHARED_CONTROL_CLIENT_NO,  SHARED_CONTROL, 	REVISION_SCHEMA,  REVISION_TYPE,  REVISION_COUNT,  REVISION_COUNT_TYPE,  REVISION_GRACE_ITEMS,  REVISION_GRACE_DATE_TYPE,
		ANNULMENTED,  ANNULMENT_REALIZE,  ANNULMENT_SCHEMA,  ANNULMENT_SCHEMA_ADVANCE,  INTEREST_REALIZE_ADV,  INTEREST_REALIZE_ADV_AMOUNT,  CHILD_DEPOSIT, CHILD_CONTROL_OWNER, CHILD_CONTROL_CLIENT_NO_1,  CHILD_CONTROL_CLIENT_NO_2,
		ACCUMULATIVE,  ACCUMULATE_PRODUCT, ACCUMULATE_AMOUNT, ACCUMULATE_MIN,  ACCUMULATE_MAX, ACCUMULATE_MAX_AMOUNT, ACCUMULATE_MAX_AMOUNT_LIMIT,  ACCUMULATE_SCHEMA_INTRATE,
		SPEND,  SPEND_INTRATE,  SPEND_AMOUNT,  SPEND_AMOUNT_INTRATE,  SPEND_CONST_AMOUNT, DEPO_REALIZE_TYPE, CREDITCARD_BALANCE_CHECK, INTEREST_REALIZE_TYPE,
		DEPO_FILL_ACC_ID,  DEPO_ACC_ID,  LOSS_ACC_ID,  ACCRUAL_ACC_ID,  DEPO_REALIZE_ACC_ID,  INTEREST_REALIZE_ACC_ID,  INTEREST_REALIZE_ADV_ACC_ID,
		RESPONSIBLE_USER_ID, DEPO_NOTE, DEPOSIT_DEFAULT) 
	VALUES																																						 
		(@depo_id, @row_version, @branch_id, @dept_no, @state, @client_no, @trust_deposit, @trust_client_no, @trust_extra_info,
		@prod_id, @agreement_no, @depo_type, @depo_acc_subtype, @depo_account_state, @iso, @agreement_amount, @amount,
		@date_type, @period, @start_date, @end_date, @annulment_date, @intrate, @real_intrate, @perc_flags, @accrue_amount_min, @accrue_amount_max, @spend_min, @spend_max,
		@formula, @days_in_year, @intrate_schema, @accrue_type, @recalculate_type,
		@realize_schema, @realize_type, @realize_count, @realize_count_type, @depo_realize_schema, @depo_realize_schema_amount, @convertible, @prolongable, NULL,
		@renewable, @renew_capitalized, @renew_max, @renew_last_prod_id, @shareable,	@shared_control_client_no, @shared_control, @revision_schema, @revision_type, @revision_count, @revision_count_type, @revision_grace_items, @revision_grace_date_type,
		@annulmented, @annulment_realize, @annulment_schema, @annulment_schema_advance, @interest_realize_adv, @interest_realize_adv_amount, @child_deposit, 0,                  @child_control_client_no_1, @child_control_client_no_2,
		@accumulative,  @accumulate_product, @accumulate_amount, @accumulate_min,  @accumulate_max, @accumulate_max_amount, @accumulate_max_amount_limit, @accumulate_schema_intrate,
		@spend, @spend_intrate, @spend_amount, @spend_amount_intrate, @spend_const_amount, @depo_realize_type, @creditcard_balance_check, @interest_realize_type,
		@depo_fill_acc_id, @depo_acc_id, @loss_acc_id, @accrual_acc_id, @depo_realize_acc_id, @interest_realize_acc_id, @interest_realize_adv_acc_id,
		@user_id, @depo_note, 0)
	IF @@ERROR <> 0 BEGIN SET IDENTITY_INSERT dbo.DEPO_DEPOSITS OFF; IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT DATA', 16, 1); RETURN (1); END
	SET IDENTITY_INSERT dbo.DEPO_DEPOSITS OFF
END

SET @formula = dbo.depo_fn_get_formula(@depo_id, default)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR GENERATE FORMULA', 16, 1); RETURN (1); END

UPDATE dbo.DEPO_DEPOSITS WITH (UPDLOCK)
SET FORMULA = @formula
WHERE DEPO_ID = @depo_id
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATING DEPOSIT DATA', 16, 1); RETURN (1); END

INSERT INTO dbo.DEPO_DEPOSIT_CHANGES(DEPO_ID, [USER_ID], DESCRIP)
VALUES(@depo_id, @user_id, 'ÓÀÀÍÀÁÒÄ áÄËÛÄÊÒÖËÄÁÉÓ ÃÀÌÀÔÄÁÀ')
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT CONTRACT LOG', 16, 1); RETURN (1); END

DECLARE
	@op_id int,
	@op_type tinyint,
	@op_data xml,
	@self_exec bit,
	@doc_rec_state bit

SELECT @self_exec = SELF_EXEC, @doc_rec_state = DOC_REC_STATE
FROM dbo.DEPO_OP_TYPES (NOLOCK)
WHERE [TYPE_ID] = dbo.depo_fn_const_op_active()
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('OPERATION NOT FOUND', 16, 1); RETURN (1); END

SET @op_type = dbo.depo_fn_const_op_active()

SET @op_data =
	(SELECT
		@client_type AS CLIENT_TYPE, 
		@depo_fill_acc_id AS DEPO_FILL_ACC_ID,
		@depo_realize_acc_id AS DEPO_REALIZE_ACC_ID,
		@interest_realize_acc_id AS INTEREST_REALIZE_ACC_ID,
		@interest_realize_adv AS INTEREST_REALIZE_ADV,
		@interest_realize_adv_acc_id AS INTEREST_REALIZE_ADV_ACC_ID,
		@interest_realize_adv_amount AS INTEREST_REALIZE_ADV_AMOUNT,
		@spend_amount AS ACC_MIN_AMOUNT,
		@state AS DEPO_PREV_STATE
	FOR XML RAW, TYPE)

INSERT INTO dbo.DEPO_OP WITH (UPDLOCK)
(DEPO_ID, OP_DATE, OP_TYPE, OP_STATE, AMOUNT, ISO, OP_DATA, BY_PROCESSING, [OWNER]) 
VALUES
(@depo_id, @start_date, @op_type, 0, @agreement_amount, @iso, @op_data, 0, @user_id)
IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR INSERT DEPOSIT OP DATA' ,16,1); RETURN (1); END

SET @op_id = SCOPE_IDENTITY()

EXEC @r = dbo.depo_sp_add_op_action
	@op_id = @op_id,
	@op_type = @op_type,	
	@depo_id = @depo_id,
	@user_id = @user_id

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR OP ADD ACTION', 16, 1); RETURN (1); END

DECLARE
	@accrue_doc_rec_id int,
	@doc_rec_id int

EXEC @r = dbo.depo_sp_add_op_accounting
	@doc_rec_id = @doc_rec_id OUTPUT,
	@accrue_doc_rec_id = @accrue_doc_rec_id OUTPUT,
	@op_id = @op_id,
	@user_id = @user_id

IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR ADD ACCOUNTING' ,16,1); RETURN (1); END

IF @doc_rec_id IS NOT NULL
BEGIN
	UPDATE dbo.DEPO_OP WITH (UPDLOCK)
	SET DOC_REC_ID = @doc_rec_id
	WHERE OP_ID = @op_id

	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK; RAISERROR ('ERROR UPDATING OPERATION DATA', 16, 1); RETURN (1); END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN


RETURN 0
GO
