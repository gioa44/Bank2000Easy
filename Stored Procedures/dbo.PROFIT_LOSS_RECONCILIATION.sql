SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- tu dagvianebit gaeshveba es procedura, IMIS GAMO, ROM AR GADAIXUROS 1 IANVRIS MERE GAXSNILI ANGARISHENI
-- unda DAVADoT SHEZGUDVA "Note_01" (movxsnat komentari)
CREATE PROCEDURE [dbo].[PROFIT_LOSS_RECONCILIATION]
	@user_id int,
	@doc_date smalldatetime,
	@calc_date smalldatetime,
	@profit_acc_id int,
	@delete_old_docs bit = 1
	
AS
SET XACT_ABORT, NOCOUNT ON;

BEGIN TRY
	BEGIN TRANSACTION;
	
	DECLARE
		@shadow_level smallint,
		@rec_id int,
		@r int,
		@acc_id int,
		@debit_id int,
		@credit_id int,
		@act_pas smallint,
		@saldo money,
		@op_code char(5),
		@descrip varchar(100)

	SET @op_code = 'PRFIT'

	IF @delete_old_docs = 1
		DELETE FROM OPS_0000
		WHERE OP_CODE = @op_code
		
	SET @shadow_level = CASE WHEN dbo.bank_open_date() < @calc_date THEN 0 ELSE -1 END

	DECLARE cc CURSOR STATIC LOCAL
		FOR
		SELECT A.ACC_ID,A.ACT_PAS, dbo.acc_get_balance(A.ACC_ID,@calc_date,0,0,@shadow_level) AS SALDO FROM ACCOUNTS A WITH (NOLOCK)
		WHERE ISO='GEL' AND A.BAL_ACC_ALT BETWEEN 6000.00 AND 9999.99--  AND ISNULL(dbo.acc_get_balance(A.ACC_ID,@calc_date,0,0,@shadow_level), 0) <> 0
		--AND A.DATE_OPEN < '20170101' -- Note_01: damatebiti piroba, tu dagviandeba gadaxurva
		ORDER BY A.ACC_ID
		OPEN cc

	FETCH NEXT FROM cc INTO @acc_id,@act_pas,@saldo
		
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @saldo <> $0.00
		BEGIN
		
			SET @debit_id = @profit_acc_id
			SET @credit_id = @acc_id
			
			IF @act_pas < 2
			BEGIN
				SET @saldo = -@saldo
				IF @saldo > $0.00
				BEGIN
					SET @debit_id = @acc_id
					SET @credit_id = @profit_acc_id
				END
				ELSE
					SET @saldo = -@saldo
				SET @descrip = 'ÛÄÌÏÓÀÅËÉÓ ÂÀÃÀÔÀÍÀ ÌÏÂÄÁÉÓ ÀÍÂÀÒÉÛÆÄ'
			END
			ELSE
			BEGIN
				IF @saldo < $0.00
				BEGIN
					SET @saldo = -@saldo
					SET @debit_id = @acc_id
					SET @credit_id = @profit_acc_id
				END
				SET @descrip = 'áÀÒãÉÓ ÂÀÃÀÔÀÍÀ ÌÏÂÄÁÉÓ ÀÍÂÀÒÉÛÆÄ'
			END
			
			EXEC @r = dbo.ADD_DOC4 @rec_id OUTPUT
				,@user_id=@user_id
				,@doc_date=@doc_date
				,@iso='GEL'
				,@amount=@saldo
				,@doc_num=1
				,@op_code=@op_code
				,@debit_id=@debit_id
				,@credit_id=@credit_id
				,@rec_state=20
				,@descrip=@descrip
				,@parent_rec_id=0
				,@owner=@user_id
				,@doc_type=98
				,@check_saldo = 0
			
			IF @r<>0
				RAISERROR('Nonzero value returned from ADD_DOC4', 16, 1)
		END
		
		FETCH NEXT FROM cc INTO @acc_id,@act_pas,@saldo	
	END

	CLOSE cc
	DEALLOCATE cc
	
	COMMIT TRANSACTION;
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
	
	DECLARE
		@msg nvarchar(2000);
		
	SET @msg = 'Error Number: ' + CAST(ERROR_NUMBER() AS nvarchar(20)) + CHAR(13) + CHAR(10) + ERROR_MESSAGE();
	
	RAISERROR(@msg, 16, 1);
	RETURN (1);
END CATCH

RETURN 0
GO
