SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[loan_open_day_until]
	@date smalldatetime,
	@user_id int,
	@loan_id int
AS

SET NOCOUNT ON;

DECLARE
	@date_str varchar(30),
	@_date smalldatetime,
	@op_id int,
	@agreement_no varchar(100),
	@r int

SELECT 
	@agreement_no = L.AGREEMENT_NO,
	@_date = CALC_DATE
FROM dbo.LOANS (NOLOCK) L
	INNER JOIN dbo.LOAN_DETAILS D (NOLOCK) ON L.LOAN_ID = D.LOAN_ID
WHERE L.LOAN_ID = @loan_id


IF NOT EXISTS (SELECT LOAN_ID FROM dbo.LOAN_DETAILS_HISTORY (NOLOCK) WHERE LOAN_ID = @loan_id AND CALC_DATE = @date)
BEGIN
	SET @date_str = CONVERT(varchar(30), @date, 102)
	RAISERROR('<ERR>ÓÄÓáÉÓ ÃÀÁÒÖÍÄÁÀ %s ÈÀÒÉÙÛÉ ÅÄÒ áÄÒáÃÄÁÀ, ÌÏÍÀÝÄÌÄÁÉ ÀÌ ÈÀÒÉÙÉÓÈÅÉÓ ÀÒ ÀÒÓÄÁÏÁÓ. (ÓÄÓáÉ: %s) !</ERR>', 16, 1, @date_str, @agreement_no)
	RETURN(1)
END

WHILE @_date > @date
BEGIN
	DECLARE cr_ops CURSOR LOCAL FOR 
	SELECT OP_ID
	FROM dbo.LOAN_OPS (NOLOCK)
	WHERE LOAN_ID = @loan_id AND OP_DATE = @_date

	OPEN cr_ops

	FETCH NEXT FROM cr_ops INTO @op_id 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC @r = dbo.LOAN_SP_DELETE_OPS @op_id, @user_id
		IF @@ERROR <> 0 OR @r <> 0
		BEGIN
			SET @date_str = CONVERT(varchar(30), @_date, 102)
			RAISERROR('ÛÄÝÃÏÌÀ %s ÈÀÒÉÙÛÉ ÄÒÈÄÒÈÉ ÏÐÄÒÀÝÉÉÓ ßÀÛËÉÓ ÃÒÏÓ. (ÓÄÓáÉ: %s) !', 16, 1, @date_str, @agreement_no)
			RETURN(1)
		END
		
		FETCH NEXT FROM cr_ops INTO @op_id 
	END
	
	CLOSE cr_ops
	DEALLOCATE cr_ops
	
	EXEC @r = dbo.LOAN_SP_LOAN_OPEN_DAY @date, @user_id, @loan_id -- @date ÐÀÒÀÌÄÔÒÓ ÀÆÒÉ ÀÒ ÀØÅÓ
	IF @@ERROR <> 0 OR @r <> 0
	BEGIN
		SET @date_str = CONVERT(varchar(30), @_date - 1, 102)
		RAISERROR('ÛÄÝÃÏÌÀ ÓÄÓáÉÓÈÅÉÓ %s ÈÀÒÉÙÉÓ ÂÀáÓÍÉÓ ÃÒÏÓ. (ÓÄÓáÉ: %s) !', 16, 1, @date_str, @agreement_no)
		RETURN(1)
	END
	
	SET @_date = @_date - 1
END


RETURN (0)
GO
