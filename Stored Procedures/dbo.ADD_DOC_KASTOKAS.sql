SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ADD_DOC_KASTOKAS]
	@sender_id int,
	@iso TISO,
	@amount money,
	@recipient_id int
AS

DECLARE 
	@sender_acc_id int, 
	@sender_acc decimal(15,0), 
	@sender_dept_id int,	

	@recipient_acc_id int,
	@recipient_acc decimal(15,0), 
	@recipient_dept_id int,

	@money_transit_acc_id int,
	@money_transit_acc TACCOUNT,

	@param_name varchar(20),
	@op_code_for_income varchar(5),
	@op_code_for_outcome varchar(5)

IF @iso = 'GEL'	
BEGIN
	SET @param_name = 'KAS_ACC'
	SET @op_code_for_income = '32'
	SET @op_code_for_outcome = '52'
END
ELSE 
BEGIN
	SET @param_name = 'KAS_ACC_V'
	SET @op_code_for_income = '29'
	SET @op_code_for_outcome = '69'
END


SELECT @sender_dept_id = DEPT_NO, @sender_acc = CASE WHEN @iso = 'GEL' THEN KAS_ACC ELSE KAS_ACC_V END
FROM dbo.USERS (NOLOCK) 
WHERE [USER_ID] = @sender_id

IF @sender_acc IS NULL
	EXEC dbo.GET_DEPT_ACC @sender_dept_id, @param_name, @sender_acc output

SET @sender_acc_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@sender_dept_id), @sender_acc, @iso)
	
IF ISNULL(@recipient_id, 0) > 0
	SELECT @recipient_dept_id = DEPT_NO, @recipient_acc = CASE WHEN @iso = 'GEL' THEN KAS_ACC ELSE KAS_ACC_V END
	FROM dbo.USERS (NOLOCK) 
	WHERE [USER_ID] = @recipient_id
ELSE
	SELECT @recipient_dept_id = @sender_dept_id, @recipient_acc = NULL

IF @recipient_acc IS NULL
	EXEC dbo.GET_DEPT_ACC @recipient_dept_id, @param_name, @recipient_acc output

SET @recipient_acc_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@recipient_dept_id), @recipient_acc, @iso)

IF @iso = 'GEL'	
	EXEC dbo.GET_DEPT_ACC @sender_dept_id, 'KAS_TRANSIT_ACC', @money_transit_acc OUTPUT
ELSE 
	EXEC dbo.GET_DEPT_ACC @sender_dept_id, 'KAS_TRANSIT_ACC_V', @money_transit_acc OUTPUT

SET @money_transit_acc_id = dbo.acc_get_acc_id(dbo.dept_branch_id(@sender_dept_id), @money_transit_acc, @iso)
IF @money_transit_acc_id IS NULL
BEGIN
	RAISERROR('ÓÀËÀÒÏÓ ÔÒÀÍÆÉÔÉÓ ÀÍÂÀÒÉÛÉ ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÂÀÍÚÏ×ÉËÄÁÄÁÉÓÀ ÃÀ ×ÉËÉÀËÄÁÉÓ ÝÍÏÁÀÒÛÉ', 16, 1)
	RETURN 1
END

DECLARE 
	@rec_id int,
	@r int,
	@doc_date smalldatetime

SET @doc_date = convert(smalldatetime,floor(convert(real,getdate())))

BEGIN TRAN

EXEC @r = dbo.ADD_DOC4           --ÓÀËÀÒÏÓ ÂÀÓÀÅÀÅËÉÓ ÏÒÃÄÒÉ
		@rec_id = @rec_id OUTPUT,
		@user_id = @sender_id,
		@doc_date = @doc_date,
		@iso = @iso,
		@amount = @amount,
		@doc_type = 130,
		@op_code = @op_code_for_outcome,
		@debit_id = @money_transit_acc_id,
		@credit_id = @sender_acc_id,
		@rec_state = 20,
		@descrip = 'ÓÀËÀÒÏÃÀÍ ÓÀËÀÒÏÆÄ ×ÖËÉÓ ÂÀÝÄÌÀ',
		@channel_id = 1
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

EXEC @r = dbo.ADD_DOC4           --ÓÀËÀÒÏÓ ÛÄÌÏÓÀÅËÉÓ ÏÒÃÄÒÉ
		@rec_id = @rec_id OUTPUT,
		@user_id = @sender_id,
		@doc_date = @doc_date,
		@iso = @iso,
		@amount = @amount,
		@doc_type = 120,
		@op_code = @op_code_for_income,
		@debit_id = @recipient_acc_id,
		@credit_id = @money_transit_acc_id,
		@rec_state = 0,
		@descrip = 'ÓÀËÀÒÏÃÀÍ ÓÀËÀÒÏÆÄ ×ÖËÉÓ ÌÉÙÄÁÀ',
		@channel_id = 1
IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @@TRANCOUNT > 0 ROLLBACK RETURN 1 END

COMMIT

RETURN @r
GO
