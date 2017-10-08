SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[so_prepare_transaction]
	@task_id int,
	@date datetime,
	@schedule_date datetime,
	@client_no int,
	@agreement_no varchar(50),
	@descrip varchar(250) OUTPUT,
	@descrip_lat varchar(250) OUTPUT,
	
	@tariff_id int,
	@user_id int,
	@dept_no int,
	@doc_type smallint,
	@doc_date datetime,
	@receiver_bank_code varchar(37) = NULL,
	@det_of_charg char(3) = NULL,
	
	@debit_acc_id int,
	@debit_acc_type int,
	@debit_ccy TISO,
	@debit_acc_sub_type int,
	@debit_acc TACCOUNT,
	
	@credit_acc_id int,
	@credit_acc_type int,
	@credit_ccy TISO,
	@credit_acc_sub_type int,
	@credit_acc TACCOUNT,
	
	@use_overdraft bit,
	@lim_amount money,
	@is_percent bit,
	@equ_iso TISO,
	@debt_action int,
	@fx_rate_type int,
	@check_saldo bit = 1,
	
	@already_used_amount money = 0,
	@transaction_amount money OUTPUT,
	@transaction_amount_equ money OUTPUT,
	@tariff_amount money = 0 OUTPUT,
	@blocked_amount money OUTPUT,
	@is_partial bit OUTPUT,
	@error_code int OUTPUT,
	@error_msg varchar(250) OUTPUT,
	@error_msg_lat varchar(250) OUTPUT,
	@ref_no int OUTPUT
AS

DECLARE
	@current_amount money,
	@rate money,
	@rate_items int,
	@is_reverse bit,
	@tmp_amount money,
	@debit_acc_id_tariff int,
	@credit_acc_id_tariff int,
	@r int
	
SET @error_code = NULL
SET @error_msg = NULL
SET @error_msg_lat = NULL

EXEC dbo.acc_get_usable_amount 
	@acc_id = @debit_acc_id, 
	@usable_amount = @current_amount OUTPUT, 
	@use_overdraft = @use_overdraft

SET @current_amount = @current_amount - ISNULL(@already_used_amount, $0.00)

EXEC dbo.so_get_ref_no @ref_no = @ref_no OUTPUT
SET @blocked_amount = NULL
SET @tariff_amount = 0

--IF @debt_action IN (1, 4) OR (@lim_amount IS NULL) OR (ISNULL(@is_percent, 0) = 1)
BEGIN
	EXEC @r = dbo.so_get_acc_balance
		@date = @date,
		@client_no = @client_no,
		@acc_id = @debit_acc_id,
		@acc_type = @debit_acc_type,
		@acc_sub_type = @debit_acc_sub_type,
		@acc_no = @debit_acc,
		@is_debit = 1,
		@ccy = @debit_ccy,
		@ref_no = @ref_no,
		@block_amount = NULL,
		@cancel_operation = 0,
		@amount = @current_amount OUTPUT,
		@check_saldo = @check_saldo OUTPUT,
		@error_code = @error_code OUTPUT,
		@error_msg = @error_msg OUTPUT,
		@error_msg_lat = @error_msg_lat OUTPUT
		
	IF (ISNULL(@error_code, 0) <> 0)
		RETURN @r
END

SET @debit_acc_id_tariff = @debit_acc_id
SET @credit_acc_id_tariff = @credit_acc_id

EXEC @r = dbo.so_calc_transaction_amount
	@date = @date,
	@balance = @current_amount,
	@lim_amount = @lim_amount,
	@is_percent = @is_percent,
	@iso = @debit_ccy,
	@equ_iso = @equ_iso,
	@debt_action = @debt_action,
	@transaction_amount = @transaction_amount OUTPUT,
	@is_partial = @is_partial OUTPUT,
	@error_code = @error_code OUTPUT,
	@error_msg = @error_msg OUTPUT,
	@error_msg_lat = @error_msg_lat OUTPUT

IF (@error_code <> 0)
	RETURN @r
	
IF (ISNULL(@is_partial, 0) = 1)
	IF (@debt_action IN (0, 2, 4))
	BEGIN
		SET @error_code = -3
		SET @error_msg = 'ÀÒÀÓÀÊÌÀÒÉÓÉ ÍÀÛÈÉ ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ!'
		SET @error_msg_lat = 'Not enough money on ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' to fulfill task!'
		RETURN @error_code
	END

IF (@tariff_id IS NOT NULL)
BEGIN
	BEGIN TRY
		EXEC @r = [dbo].[get_tariff_amount]
			@result = @tariff_amount OUTPUT,
			@tariff_id = @tariff_id,
			@client_no = @client_no,
			@descrip = NULL,
			@user_id = @user_id,
			@dept_no = @dept_no,
			@doc_type = @doc_type,
			@doc_date = @date,
			@flags = NULL,
			@debit_id = @debit_acc_id_tariff OUTPUT,
			@credit_id = @credit_acc_id_tariff OUTPUT,
			@iso = @debit_ccy,
			@amount = @transaction_amount,
			@amount2 = @transaction_amount,
			@cash_amount = 0,
			@receiver_bank_code = @receiver_bank_code,
			@det_of_charg = @det_of_charg,
			@rate_flags = 0,				--?
			@info = 1

		IF (@@ERROR <> 0 OR @r <> 0)
		BEGIN
			SET @error_code = -4
			SET @error_msg = '<ERR>ÅÄÒ ÌÏáÄÒáÃÀ ÔÀÒÉ×ÉÓ ÂÀÍÓÀÆÙÅÒÀ!</ERR>'
			SET @error_msg_lat = '<ERR>Unable was to determine tariff!</ERR>'
			
			RETURN @error_code
		END

		IF (@debit_acc_id <> @debit_acc_id_tariff)
			SET @tariff_amount = 0
			
		IF (@lim_amount IS NULL)
			SET @transaction_amount = @transaction_amount - @tariff_amount
	END TRY
	BEGIN CATCH
		SET @error_code = -4
		SET @error_msg = ERROR_MESSAGE()
		SET @error_msg_lat = ERROR_MESSAGE()
		
		IF (CHARINDEX('</ERR>', @error_msg) = 0)
			SET @error_msg = '<ERR>' + @error_msg + '</ERR>'
		
		IF (CHARINDEX('</ERR>', @error_msg_lat) = 0)
			SET @error_msg_lat = '<ERR>' + @error_msg_lat + '</ERR>'
		
		RETURN @error_code
	END CATCH
END

SET @blocked_amount = @transaction_amount + @tariff_amount
--select @transaction_amount as TR, @current_amount AS CA, @blocked_amount AS BL, @tariff_amount AS TARR
IF (@current_amount < @blocked_amount) OR (@current_amount < @tariff_amount)
BEGIN
	SET @is_partial = 1
	IF @debt_action IN (0, 2, 4)
	BEGIN
		SET @error_code = -3
		SET @error_msg = 'ÀÒÀÓÀÊÌÀÒÉÓÉ ÍÀÛÈÉ ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ!'
		SET @error_msg_lat = 'Not enough money on ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' to fulfill task!'
	END
	ELSE
	BEGIN
		IF (@debt_action  <> 3)
		BEGIN
			SET @blocked_amount = @current_amount - @tariff_amount
			SET @transaction_amount = @blocked_amount
		END
		
		IF (@transaction_amount < 0)
		BEGIN
			SET @error_code = -3
			SET @error_msg = 'ÀÒÀÓÀÊÌÀÒÉÓÉ ÍÀÛÈÉ ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' ÃÀÅÀËÄÁÉÓ ÛÄÓÒÖËÄÁÉÓÀÈÅÉÓ!'
			SET @error_msg_lat = 'Not enough money on ' + CONVERT(varchar(40), @debit_acc) + '\'+ @debit_ccy + ' to fulfill task!'
		END
	END
	RETURN @error_code
END

EXEC @r = dbo.so_get_acc_balance
	@date = @date,
	@client_no = @client_no,
	@acc_id = @debit_acc_id,
	@acc_type = @debit_acc_type,
	@acc_sub_type = @debit_acc_sub_type,
	@acc_no = @debit_acc,
	@is_debit = 1,
	@ccy = @debit_ccy,
	@ref_no = @ref_no,
	@block_amount = @blocked_amount,
	@cancel_operation = 0,
	@amount = @current_amount OUTPUT,
	@check_saldo = @check_saldo OUTPUT,
	@error_code = @error_code OUTPUT,
	@error_msg = @error_msg OUTPUT,
	@error_msg_lat = @error_msg_lat OUTPUT
	
IF (ISNULL(@error_code, 0) <> 0)
	RETURN @r
	
EXEC @r = dbo.so_generate_transaction_descrip
		@task_id = @task_id,
		@ccy1 = @debit_ccy, 
		@ccy2 = @equ_iso, 
		@schedule_date = @schedule_date, 
		@client_no = @client_no,
		@agreement_no = @agreement_no,
		@descrip = @descrip OUTPUT, 
		@descrip_lat = @descrip_lat OUTPUT

IF @r <> 0
	RETURN @r

IF (@debit_ccy <> @credit_ccy)
BEGIN
	IF (@fx_rate_type = 1)
		SET @transaction_amount_equ = dbo.get_cross_amount(@transaction_amount, @debit_ccy, @credit_ccy, @date)
	ELSE
	BEGIN
		EXEC dbo.GET_CROSS_RATE 
			@rate_politics_id = NULL, 
			@iso1 = @debit_ccy, 
			@iso2 = @credit_ccy, 
			@look_buy = 0/*?*/, 
			@amount = @rate OUTPUT, 
			@items = @rate_items OUTPUT, 
			@reverse = @is_reverse OUTPUT, 
			@rate_type = 0

		IF @is_reverse = 0
		BEGIN
			SET @tmp_amount = @transaction_amount * @rate
			SET @transaction_amount_equ = @tmp_amount / @rate_items
		END
		ELSE
		BEGIN
			SET @tmp_amount = @transaction_amount * @rate_items
			SET @transaction_amount_equ = @tmp_amount / @rate
		END
	END
END
GO
