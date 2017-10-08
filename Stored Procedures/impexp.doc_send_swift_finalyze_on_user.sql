SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE [impexp].[doc_send_swift_finalyze_on_user]
	@doc_rec_id int,
	@finalyze_doc_rec_id int,
	@new_state int,
	@user_id int,
	@new_doc_rec_id int OUTPUT
AS
SET @new_doc_rec_id = 0 --თუ ამ პროცედურაში დაამატებთ რაიმე საბუთს აქ დააბრუნდეთ მისი REC_ID

-- მხოლოდ TBC
DECLARE
	@r int,
	@head_branch_dept_no int,
	@trf_debit_id int,
	@trf_credit_id int,
	@trf_amount money

EXEC dbo.GET_SETTING_INT 'HEAD_BRANCH_DEPT_NO', @head_branch_dept_no OUTPUT

DECLARE
	@iso TISO,
	@amount money,
	@correspondent_bank_id int,
	@receiver_institution_code varchar(37)

DECLARE
	@finalyze_date smalldatetime,
	@finalyze_acc_id int,
	@finalyze_iso TISO,
	@finalyze_amount money

SELECT
	@iso = ISO,
	@amount = AMOUNT,
	@correspondent_bank_id = CORRESPONDENT_BANK_ID,
	@finalyze_date = FINALYZE_DATE,
	@finalyze_acc_id = FINALYZE_ACC_ID,
	@finalyze_iso = FINALYZE_ISO,
	@finalyze_amount = FINALYZE_AMOUNT
FROM impexp.DOCS_OUT_SWIFT (NOLOCK)
WHERE DOC_REC_ID = @doc_rec_id

SELECT @receiver_institution_code = BIC
FROM dbo.CORRESPONDENT_BANKS (NOLOCK)
WHERE REC_ID = @correspondent_bank_id

SET @trf_amount = $0.00

IF @iso <> @finalyze_iso RETURN 0

IF @receiver_institution_code = 'DRESDEFF' AND @iso = 'EUR' AND dbo.acc_get_account(@finalyze_acc_id) = 72911
BEGIN
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @iso)
	SET @trf_credit_id = @finalyze_acc_id
	SET @trf_amount = CASE WHEN @amount <= 12500 THEN $3.00 ELSE $10.00 END
END

IF @receiver_institution_code = 'DEUTDEFF' AND @iso = 'EUR' AND dbo.acc_get_account(@finalyze_acc_id) = 72704
BEGIN
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @iso)
	SET @trf_credit_id = @finalyze_acc_id
	SET @trf_amount = CASE
			WHEN @amount <= $2500.00 THEN $3.50
			WHEN @amount > $2500.00 AND @amount <= $10000.00 THEN $7.00
			WHEN @amount > $10000.00 AND @amount <= $25000.00 THEN $8.50
			WHEN @amount > $25000.00 AND @amount <= $100000.00 THEN $12.50
			WHEN @amount > $100000.00 THEN $15.00
		END
END

IF @receiver_institution_code = 'IMBKRUMM' AND @iso = 'RUR' AND dbo.acc_get_account(@finalyze_acc_id) = 171202001
BEGIN
	SET @trf_debit_id = dbo.acc_get_acc_id(@head_branch_dept_no, 804402141, @iso)
	SET @trf_credit_id = @finalyze_acc_id
	SET @trf_amount = $6.00
END


IF ISNULL(@trf_amount, $0.00) <> $0.00
BEGIN
	EXEC @r = dbo.ADD_DOC4
		@rec_id = @new_doc_rec_id OUTPUT,
		@user_id = @user_id,
		@doc_type = 98,
		@doc_date = @finalyze_date,
		@doc_date_in_doc = @finalyze_date,
		@debit_id = @trf_debit_id,
		@credit_id = @trf_credit_id,
		@iso = @iso,
		@amount = @trf_amount,
		@rec_state = 20,
		@parent_rec_id = @finalyze_doc_rec_id, 
		@descrip = 'ÂÀÃÀÒÉÝáÅÀÆÄ ÌÏÌÓÀáÖÒÄÁÉÓ ÓÀÊÏÌÉÓÉÏ',
		@op_code = 'SCHRG',
		@channel_id = 605,
		@foreign_id = @doc_rec_id
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT>0 ROLLBACK RETURN 1 END
END
-- End OF მხოლოდ TBC

RETURN
GO
