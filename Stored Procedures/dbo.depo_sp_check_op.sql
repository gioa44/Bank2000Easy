SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_check_op]
	@depo_id int,
	@op_date smalldatetime,
	@op_type smallint,
	@op_state bit,
	@op_amount money,
	@op_iso CHAR(3),
	@op_data XML, 
	@user_id int
AS
	SET NOCOUNT ON;
	
	DECLARE
		@r int,
		@last_calc_date smalldatetime

	IF @op_type = dbo.depo_fn_const_op_annulment()
	BEGIN
		SELECT @last_calc_date = P.LAST_CALC_DATE
		FROM dbo.DEPO_DEPOSITS (NOLOCK)D
			INNER JOIN dbo.ACCOUNTS_CRED_PERC (NOLOCK) P ON D.DEPO_ACC_ID = P.ACC_ID
		WHERE D.DEPO_ID = @depo_id
		
		IF @last_calc_date = @op_date
		BEGIN 
			RAISERROR('ÃÀÒÙÅÄÅÉÓ ÈÀÒÉÙÉ ÄÌÈáÅÄÅÀ ÁÏËÏ ÃÀÒÉÝáÅÉÓ ÈÀÒÉÙÓ. ßÀÛÀËÄÈ ÁÏËÏ ÃÀÒÉÝáÅÉÓ ÓÀÁÖÈÉ ÃÀ ÃÀÒÙÅÄÅÉÓ ÏÐÄÒÀÝÉÀ ÜÀÀÔÀÒÄÈ áÄËÀáËÀ!', 16, 1)
			RETURN(1)
		END
	END
	
	EXEC @r = dbo.depo_sp_check_op_on_user
		@depo_id = @depo_id,
		@op_date = @op_date,
		@op_type = @op_type,
		@op_state = @op_state,
		@op_amount = @op_amount,
		@op_iso = @op_iso,
		@op_data = @op_data,
		@user_id = @user_id
		
	IF @@ERROR <> 0
		RETURN 1;

RETURN @r;
GO
