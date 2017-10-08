SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_add_tcd_doc]
	@user_id int,				-- ვინ ამატებს საბუთს
	@owner int = NULL,			-- პატრონი (გაჩუმებით = @user_id)
	@rec_id int = NULL,			-- საბუთის ID
	@tcd_serial_id varchar(50),		-- სეიფის ნომერი
	@doc_date smalldatetime,	-- ტრანზაქციის თარიღი
	@iso TISO = 'GEL',			-- ვალუტის კოდი
	@amount money, 				-- თანხა
	@credit_id int				-- კრედიტის ანგარიში
								
AS
SET NOCOUNT ON

DECLARE 
	@r int,
	@doc_rec_id int,
	@branch_id int,	
	
	@tcd_acc_id int,
	@transit_acc_id int,

	@tcd_account TACCOUNT,
	@transit_account TACCOUNT,
	@cashier_account TACCOUNT,
	@dept_no int,
	@user_descrip varchar(30)

IF @owner IS NULL 
  SET @owner = @user_id
																									
SELECT	@branch_id=BRANCH_ID, @tcd_account = CASE WHEN @iso = 'GEL' THEN ACCOUNT ELSE ACCOUNT_V END,
		@transit_account = CASE WHEN @iso = 'GEL' THEN TRANSIT_ACCOUNT ELSE TRANSIT_ACCOUNT_V END
FROM dbo.TCDS
WHERE TCD_SERIAL_ID = @tcd_serial_id

SET @tcd_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_account, @iso)
SET @transit_acc_id = dbo.acc_get_acc_id(@branch_id, @transit_account, @iso)

SELECT @user_descrip = USER_FULL_NAME
FROM dbo.USERS
WHERE USER_ID = @user_id


IF @credit_id = 0
BEGIN
	SET @dept_no = dbo.user_dept_no(@user_id)
	IF @iso = 'GEL'
	BEGIN
		EXEC dbo.GET_CASHIER_ACC
			@dept_id = @dept_no,
			@user_id = @user_id,
			@param_name = 'KAS_ACC',
			@acc = @cashier_account OUTPUT
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('CASHIER ACCOUNT NOT FOUND',16,1) END RETURN END

	END
	ELSE
	BEGIN
		EXEC dbo.GET_CASHIER_ACC	
			@dept_id = @dept_no,
			@user_id = @user_id,
			@param_name = 'KAS_ACC_V',
			@acc = @cashier_account OUTPUT
		IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('CASHIER ACCOUNT NOT FOUND',16,1) END RETURN END
	END
	SET @credit_id = dbo.acc_get_acc_id(dbo.user_branch_id(@user_id), @cashier_account, @iso)
END

IF @tcd_acc_id <> @credit_id
BEGIN

	BEGIN TRAN
	
	EXEC @r=dbo.ADD_DOC4 
			@rec_id=@doc_rec_id OUTPUT,	
			@user_id=@user_id,
			@doc_date=@doc_date,
			@iso=@iso,
			@amount=@amount,
			@op_code='56',
			@debit_id=@transit_acc_id,
			@credit_id=@tcd_acc_id,
			@rec_state=20,
			@descrip='×ÉËÉÀËÉÓ ÌÏËÀÒÄÄÁÓ ÛÏÒÉÓ ÍÀÙÃÉ ×ÖËÉÓ ÌÉÌÏØÝÄÅÀ',
			@owner=@owner,
			@doc_type=130,
			@channel_id=60,
			@relation_id=@rec_id,
			@flags=0,
			@first_name=@user_descrip,
			@last_name=@user_descrip,
			@country='GE',
			@passport_type_id=0,
			@check_saldo=0,
			@add_tariff=0,
			@cashier = @user_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ TCD ÀÐÀÒÀÔÉÃÀÍ ÔÒÀÍÆÉÔÆÄ ÈÀÍáÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1) END RETURN END
														
	EXEC @r=dbo.ADD_DOC4 
			@rec_id=@doc_rec_id OUTPUT,
			@user_id=@user_id,
			@doc_date=@doc_date,
			@iso=@iso,
			@amount=@amount,
			@op_code='16',
			@debit_id=@credit_id,
			@credit_id=@transit_acc_id,
			@rec_state=20,
			@descrip='×ÉËÉÀËÉÓ ÌÏËÀÒÄÄÁÓ ÛÏÒÉÓ ÍÀÙÃÉ ×ÖËÉÓ ÌÉÌÏØÝÄÅÀ',
			@owner=@owner,
			@doc_type=120,
			@channel_id=60,
			@relation_id=@rec_id,
			@flags=0,
			@first_name=@user_descrip,
			@last_name=@user_descrip,
			@country='GE',
			@passport_type_id=0,
			@check_saldo=0,
			@add_tariff=0,
			@cashier=@user_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÔÒÀÍÆÉÔÉÃÀÍ ÓÀËÀÒÏÓ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÂÀÃÀÔÀÍÉÓÀÓ.',16,1) END RETURN END
	
	COMMIT
END

RETURN @@ERROR
GO
