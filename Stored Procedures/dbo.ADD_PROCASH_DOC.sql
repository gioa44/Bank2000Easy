SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ADD_PROCASH_DOC]
	@user_id int,				-- ვინ ამატებს საბუთს
	@owner int = NULL,			-- პატრონი (გაჩუმებით = @user_id)
	@rec_id int = NULL,			-- საბუთის ID
	@safe_nr varchar(9),		-- სეიფის ნომერი
	@doc_date smalldatetime,	-- ტრანზაქციის თარიღი
	@iso TISO = 'GEL',			-- ვალუტის კოდი
	@amount money, 				-- თანხა
	@credit_id int				-- კრედიტის ანგარიში
								
AS
SET NOCOUNT ON

DECLARE 
	@r int,
	@doc_rec_id int,
	@procash_acc_id int,
	@transit_id int,
	@branch_id int,
	@procash_acc TACCOUNT,
	@transit_acc TACCOUNT,
	@cashier_acc TACCOUNT,
	@transit_acc_id int,
	@dept_no int

IF @owner IS NULL 
  SET @owner = @user_id

SELECT	@dept_no=DEPT_NO, @procash_acc = CASE WHEN @iso = 'GEL' THEN PROCASH_ACC_N ELSE PROCASH_ACC_V END,
		@transit_acc = CASE WHEN @iso = 'GEL' THEN TRANSIT_ACC_N ELSE TRANSIT_ACC_V END
FROM	dbo.PROCASH
WHERE	SAFE_NR = @safe_nr

SET @branch_id = dbo.dept_branch_id(@dept_no)
SET @procash_acc_id = dbo.acc_get_acc_id(@branch_id, @procash_acc, @iso)
SET @transit_acc_id = dbo.acc_get_acc_id(@branch_id, @transit_acc, @iso)
--SET @dept_no = dbo.user_dept_no(@user_id)

BEGIN TRAN

EXEC @r=dbo.ADD_DOC4 @rec_id=@doc_rec_id OUTPUT,@user_id=@user_id
	,@doc_date=@doc_date,@iso=@iso,@amount=@amount,@op_code='56',@debit_id=@transit_acc_id,@credit_id=@procash_acc_id,@rec_state=20
	,@descrip='×ÉËÉÀËÉÓ ÌÏËÀÒÄÄÁÓ ÛÏÒÉÓ ÍÀÙÃÉ ×ÖËÉÓ ÌÉÌÏØÝÄÅÀ',@owner=@owner,@doc_type=130,@channel_id=2,@relation_id=@rec_id
	,@flags=0,@first_name='ÐÒÏØÄÛÉ',@last_name='ÐÒÏØÄÛÉ',@country='GE',@passport_type_id=0,@check_saldo=0,@add_tariff=0
	,@cashier=null
IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÐÒÏØÄÛÉÃÀÍ ÔÒÀÍÆÉÔÆÄ ÈÀÍáÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1) END RETURN END


SELECT @cashier_acc = CASE WHEN @iso = 'GEL' THEN KAS_ACC ELSE KAS_ACC_V END
FROM dbo.USERS (NOLOCK)
WHERE [USER_ID] = @user_id

IF @cashier_acc IS NOT NULL
BEGIN
	SET @credit_id = dbo.acc_get_acc_id(@branch_id, @cashier_acc, @iso)
END

EXEC @r=dbo.ADD_DOC4 @rec_id=@doc_rec_id OUTPUT,@user_id=@user_id
	,@doc_date=@doc_date,@iso=@iso,@amount=@amount,@op_code='16',@debit_id=@credit_id,@credit_id=@transit_acc_id,@rec_state=20
	,@descrip='×ÉËÉÀËÉÓ ÌÏËÀÒÄÄÁÓ ÛÏÒÉÓ ÍÀÙÃÉ ×ÖËÉÓ ÌÉÌÏØÝÄÅÀ',@owner=@owner,@doc_type=120,@channel_id=1,@relation_id=@rec_id
	,@flags=0,@first_name='ÐÒÏØÄÛÉ',@last_name='ÐÒÏØÄÛÉ',@country='GE',@passport_type_id=0,@check_saldo=0,@add_tariff=0
	,@cashier=@user_id
IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÔÒÀÍÆÉÔÉÃÀÍ ÓÀËÀÒÏÓ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÂÀÃÀÔÀÍÉÓÀÓ.',16,1) END RETURN END

COMMIT
RETURN @@ERROR
GO
