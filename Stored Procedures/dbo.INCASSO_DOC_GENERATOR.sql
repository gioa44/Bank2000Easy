SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[INCASSO_DOC_GENERATOR]
	@rec_id int,
	@user_id int,
	@doc_date smalldatetime,
	@aut_level int
AS

SET NOCOUNT ON

DECLARE
	@r int,
	@incasso_ops_id int,
	@incasso_num varchar(20),
	@acc_id int,
	@acc_id2 int,
	@usable_amount money,
	@saved_amount money,
	@incasso_amount money,
	@incasso_ccy char(3),
	@acc_ccy char(3),
	@issue_date smalldatetime,
	@main_acc_usable_amount money


IF NOT EXISTS(SELECT * FROM dbo.INCASSO (NOLOCK) WHERE REC_ID = @rec_id)
BEGIN 
	RAISERROR ('ÛÄÝÃÏÌÀ. ÀÓÄÈÉ ÉÍÊÀÓÏ ÀÒ ÀÒÓÄÁÏÁÓ.',16,1) 
	RETURN 1 
END

SELECT @r = REC_STATE, @usable_amount = BALANCE
FROM dbo.INCASSO (NOLOCK) 
WHERE REC_ID = @rec_id

IF @r IS NULL
BEGIN 
	RAISERROR ('ÛÄÝÃÏÌÀ. ÀÓÄÈÉ ÉÍÊÀÓÏ ÀÒ ÀÒÓÄÁÏÁÓ.',16,1) 
	RETURN 1 
END

IF @r <> 1 OR @usable_amount <= $0.00
	RETURN 0

BEGIN TRAN

SET @doc_date = convert(smalldatetime,floor(convert(real,@doc_date)))

SELECT	@acc_id = ACC_ID, @incasso_num = INCASSO_NUM, @incasso_amount = BALANCE, @incasso_ccy=ISO, @issue_date=ISSUE_DATE
FROM	dbo.INCASSO (NOLOCK)
WHERE	REC_ID = @rec_id


DECLARE @descrip varchar(150)
SET @descrip = 'ÉÍÊÀÓÏÓ ÀÍÂÀÒÉÛÆÄ ÈÀÍáÉÓ ÛÄÂÒÏÅÄÁÀ, ÉÍÊÀÓÏ # ' + @incasso_num + ', ' + CONVERT(varchar(10), @issue_date, 103)

SET @incasso_amount = ROUND(dbo.get_equ (@incasso_amount, @incasso_ccy, @doc_date), 2)

SET @main_acc_usable_amount = dbo.acc_get_incasso_usable_amount (@acc_id)

DECLARE @sum_amount money,
		@amount money,
		@amount_val money,
		@add_doc_rec_id int,
		@dept_no int

SET @dept_no = dbo.user_dept_no(@user_id)
SET @sum_amount = $0.00

DECLARE cur CURSOR LOCAL FOR
	SELECT IA.ACC_ID, IA.AMOUNT
	FROM dbo.INCASSO_ACCOUNTS IA
	WHERE IA.INCASSO_ID = @rec_id
	ORDER BY REC_ID

OPEN cur
IF @@ERROR <> 0  GOTO Finish

FETCH NEXT FROM cur INTO @acc_id2, @saved_amount
IF @@ERROR <> 0 GOTO Finish

WHILE @@FETCH_STATUS = 0
BEGIN
	IF @acc_id2 = @acc_id -- Main Account
		SET @amount = @main_acc_usable_amount
	ELSE
		SET @amount = dbo.acc_get_incasso_usable_amount (@acc_id2)

	IF @saved_amount < 0 -- ÂÀÅÉÈÅÀËÉÓßÉÍÏÈ ÏÅÄÒÃÒÀ×ÔÉ ÉÍÊÀÓÏÓ ÃÀÃÄÁÀÌÃÄ
		SET @amount = @amount - @saved_amount 

	IF @amount < $0.00
		SET @amount = $0.00

	IF @amount > $0.00
	BEGIN
		SET @acc_ccy = dbo.acc_get_ccy(@acc_id2)
		SET @amount_val = @amount
		SET @amount = ROUND(dbo.get_equ (@amount, @acc_ccy, @doc_date), 2)

		IF (@sum_amount + @amount) <= @incasso_amount
		BEGIN
			SET @sum_amount = @sum_amount + @amount
		END
		ELSE
		BEGIN
			SET @amount = (@incasso_amount - @sum_amount)		
			
			IF @acc_ccy <> 'GEL'
			BEGIN
				SET @amount_val = ROUND(dbo.get_cross_amount(@amount, 'GEL', @acc_ccy, @doc_date), 2)

				IF @amount_val = $0.00
					SET @amount = $0.00
				ELSE
				BEGIN
					--SET @amount = ROUND(dbo.get_equ (@amount_val, @acc_ccy, @doc_date), 2)
					IF ROUND(dbo.get_equ (@amount_val, @acc_ccy, @doc_date), 2) = 0
						SET @amount = $0.00
				END
			END

			SET @sum_amount = @sum_amount + @amount
		END

		IF @amount > $0.00 AND @acc_id2 <> @acc_id
		BEGIN
			IF @acc_ccy = 'GEL'
			BEGIN
				EXEC @r = dbo.ADD_DOC4 @rec_id=@add_doc_rec_id OUTPUT, @user_id=@user_id,@doc_date=@doc_date,@doc_date_in_doc=@doc_date,@iso=@acc_ccy, @amount=@amount,@op_code='*INK',
					@debit_id=@acc_id2, @credit_id=@acc_id, @rec_state=20, @descrip=@descrip, @owner=@user_id, @doc_type=98,
					@channel_id=0, @dept_no=@dept_no, @foreign_id=0, @check_saldo=0, @add_tariff=0, @flags=6
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÌÄÌÏÒÉÀËÖÒÉ ÏÒÃÄÒÉÓ ÂÀÔÀÒÄÁÉÓÀÓ.',16,1) END RETURN 1 END
			END
			ELSE
			BEGIN
				DECLARE @rec_id_2 int

				EXEC @r = dbo.ADD_CONV_DOC4 @add_doc_rec_id OUTPUT,@rec_id_2 OUTPUT,@user_id=@user_id,@dept_no=@dept_no,
						@is_kassa=0,@descrip1=@descrip,@descrip2=@descrip,@rec_state=20,
						@doc_num=0,@op_code='*INK',@doc_date=@doc_date,
						@iso_d=@acc_ccy,@iso_c=@incasso_ccy,@amount_d=@amount_val,@amount_c=@amount,
						@debit_id=@acc_id2,@credit_id=@acc_id,@tariff_kind=0,@info=0,@add_tariff=0,@check_saldo=0,@flags=6
				IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÊÏÍÅÄÒÔÀÝÉÉÓÀÓ.',16,1) END RETURN 1 END
			END

			INSERT INTO dbo.INCASSO_OPS_ID(INCASSO_OP_ID, DOC_REC_ID)
			VALUES (-1, @add_doc_rec_id)
			IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÄÁÉÓ ID-ÄÁÉÓ ÜÀßÄÒÉÓÀÓ.',16,1) END RETURN 99 END
		END
		IF @sum_amount >= @incasso_amount
			GOTO Finish
	END

	FETCH NEXT FROM cur INTO @acc_id2, @saved_amount
	IF @@ERROR <> 0 GOTO Finish
END

Finish:
CLOSE cur
DEALLOCATE cur


IF @sum_amount > 0
BEGIN
print @sum_amount 
	EXEC @r = dbo.ADD_INCASSO_DOC	
		@rec_id=@add_doc_rec_id OUTPUT, @incasso_id = @rec_id, @user_id=@user_id, 
		@doc_date=@doc_date, @amount=@sum_amount, @aut_level=10
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÃÀ×ÀÒÅÉÓ ÃÀÂÄÍÄÒÉÒÄÁÉÓÀÓ.',16,1) END RETURN 99 END
	
	INSERT INTO dbo.INCASSO_OPS_ID(INCASSO_OP_ID, DOC_REC_ID)
	VALUES (-1, @add_doc_rec_id)
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÄÁÉÓ ID-ÄÁÉÓ ÜÀßÄÒÉÓÀÓ.',16,1) END RETURN 99 END

	EXEC @r = dbo.ADD_INCASSO_OPS @rec_id=@incasso_ops_id OUTPUT, @user_id=@user_id, @incasso_id=@rec_id,
		@op_type=0,	@amount=@sum_amount, @doc_num=@incasso_num, @doc_date=@issue_date
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 99 END

	UPDATE	dbo.INCASSO_OPS_ID
	SET		INCASSO_OP_ID = @incasso_ops_id
	WHERE	INCASSO_OP_ID = -1
	IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 99 END

	EXEC @r = dbo.AUTHORIZE_INCASSO @rec_id=@incasso_ops_id, @user_id=@user_id
	IF @@ERROR<>0 OR @r<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ ÉÍÊÀÓÏÓ ÏÐÄÒÀÝÉÉÓ ÃÀÌÀÔÄÁÉÓÀÓ.',16,1) END RETURN 99 END
END

COMMIT

RETURN 0
GO
