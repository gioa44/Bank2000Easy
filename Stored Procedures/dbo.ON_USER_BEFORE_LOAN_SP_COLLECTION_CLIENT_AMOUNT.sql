SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[ON_USER_BEFORE_LOAN_SP_COLLECTION_CLIENT_AMOUNT]
	@user_id int,
	@date smalldatetime,
	@loan_id int,
	@iso TISO,
	@acc_id int,
	@client_no int,
	@debt_amount money,
	@acc_overlimit_amount money out,
	@simulate bit
AS
SET NOCOUNT ON;
/* Fill #acc_balance TABLE
#acc_balance
(
	PRIORITY_ID	int NOT NULL PRIMARY KEY,
	ACC_ID int NOT NULL,
	ISO char(3) NOT NULL,
	AMOUNT money NOT NULL,
	AMOUNT_EQU money NULL,
	ACC_TYPE tinyint NULL,
	ACC_SUBTYPE int NULL,
	RATE_AMOUNT money NULL,
	RATE_ITEMS int NULL,
	RATE_REVERSE bit NULL,
	DOC_REC_ID int NULL
)
*/
/* რესპუბლიკა */
	DECLARE
		@client_type int,
		@acc_type int,
		@acc_subtype int,
		@_iso char(3),
		@use_overdraft bit,
		@acc_usable_amount money,
		@acc_usable_amount_equ money,		
		@_acc_id int,
		@amount money,
		@amount_equ money,
		@priority int,
		@acc_client_no int,
		@rate_amount money,
		@rate_items int,
		@rate_reverse bit
	
	SET @acc_overlimit_amount = $0.00
	IF (@debt_amount = 0 OR EXISTS(SELECT * FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id AND (IS_INCASSO = 1 OR REC_STATE <> 1)))
		RETURN(0)
			
	DECLARE 
		@priority_list TABLE
						(
							PRIORITY int PRIMARY KEY,							
							ACC_TYPE int NOT NULL,
							ACC_SUBTYPE int NULL,
							ISO char(3) NOT NULL,
							USE_OVERDRAFT bit NOT NULL
						)

	DECLARE
		@except_list TABLE
						(
							ACC_TYPE int NOT NULL,
							ACC_SUBTYPE int NOT NULL,
							ISO char(3) NULL,
							USE_OVERDRAFT bit NOT NULL
							PRIMARY KEY (ACC_TYPE, ACC_SUBTYPE)
						)
	
	SELECT @acc_client_no = CLIENT_NO FROM dbo.ACCOUNTS (NOLOCK) WHERE ACC_ID = @acc_id	

	
	SET @acc_usable_amount = $0.00
	SET @priority = 1
	
	EXEC dbo.acc_get_usable_amount 
				@acc_id = @acc_id,
				@usable_amount = @acc_overlimit_amount out,
				@use_overdraft = 1
				
	SET @acc_overlimit_amount = CASE WHEN @acc_overlimit_amount < $0.00 THEN -@acc_overlimit_amount ELSE $0.00 END	
	SET @debt_amount = @debt_amount + @acc_overlimit_amount

	IF (@acc_client_no IS NULL) OR (@acc_client_no = @client_no)
	BEGIN
		EXEC dbo.acc_get_usable_amount 
					@acc_id = @acc_id,
					@usable_amount = @acc_usable_amount out,
					@use_overdraft = 0

		IF (@acc_usable_amount > $0.00)
		BEGIN
			IF (@debt_amount <= @acc_usable_amount)
				SET @amount = @debt_amount
			ELSE
				SET @amount = @acc_usable_amount
					
			INSERT INTO #acc_balance 
			VALUES(@priority, @acc_id, @iso, @amount, @amount, NULL, NULL, NULL, NULL, NULL, NULL)

			SET @priority = @priority + 1

			SET @debt_amount = @debt_amount - @amount
		
			IF (@debt_amount <= 0)
				RETURN(0)
		END
	END
	
	SELECT @client_type = CLIENT_TYPE 
	FROM dbo.CLIENTS (NOLOCK)
	WHERE CLIENT_NO = @client_no

	BEGIN TRY

		IF (@client_type = 1 /* ფიზიკური პირი*/)
		BEGIN	
			INSERT INTO @priority_list VALUES(1, 100 /* მიმდინარე */, NULL, @iso, 0)		 
			--GIO: SXVA VALUTIS ANGARISHEBIDAN ROM AR DAAKONVERTIROS ORIVEGAN 3-3 STRIQONI DAVAKOMENTARE
			--INSERT INTO @priority_list	VALUES(3, 100 /* მიმდინარე */, NULL, CASE WHEN @iso = 'GEL' THEN 'USD' ELSE 'GEL' END, 0)
			--INSERT INTO @priority_list	VALUES(5, 100 /* მიმდინარე */, NULL, CASE WHEN @iso IN ('GEL', 'USD') THEN 'EUR' ELSE 'USD' END, 0)
			--INSERT INTO @priority_list	VALUES(7, 100 /* მიმდინარე */, NULL, CASE WHEN @iso = 'GBP' THEN 'EUR' ELSE 'GBP' END, 0)
		END
		ELSE
		BEGIN
			INSERT INTO @priority_list	VALUES(1, 100 /* მიმდინარე */, NULL, @iso, 0)
			--INSERT INTO @priority_list	VALUES(3, 100 /* მიმდინარე */, NULL, CASE WHEN @iso = 'GEL' THEN 'USD' ELSE 'GEL' END, 0)
			--INSERT INTO @priority_list	VALUES(5, 100 /* მიმდინარე */, NULL, CASE WHEN @iso IN ('GEL', 'USD') THEN 'EUR' ELSE 'USD' END, 0)
			--INSERT INTO @priority_list	VALUES(7, 100 /* მიმდინარე */, NULL, CASE WHEN @iso = 'GBP' THEN 'EUR' ELSE 'GBP' END, 0)
		END

		/* გამონაკლისების შევსება */

		INSERT INTO @except_list(ACC_TYPE, ACC_SUBTYPE, ISO, USE_OVERDRAFT) VALUES(200, 2, NULL, 1)

		DECLARE priority_list CURSOR LOCAL FAST_FORWARD FOR
			SELECT ACC_TYPE, ACC_SUBTYPE, ISO, USE_OVERDRAFT FROM @priority_list ORDER BY PRIORITY

		OPEN priority_list

		FETCH NEXT FROM priority_list INTO @acc_type, @acc_subtype, @_iso, @use_overdraft

		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			SET @acc_usable_amount = $0.00
			SET @acc_usable_amount_equ = $0.00

			DECLARE cr CURSOR LOCAL FAST_FORWARD FOR
				SELECT ACC_ID FROM dbo.ACCOUNTS (NOLOCK) t
				WHERE CLIENT_NO = @client_no AND ISO = @_iso AND ACC_TYPE = @acc_type AND (@acc_subtype IS NULL OR ACC_SUBTYPE = @acc_subtype) AND REC_STATE = 1 AND IS_INCASSO = 0 AND 
					(ACC_ID <> @acc_id OR @use_overdraft = 1) AND
					NOT EXISTS (SELECT * FROM @except_list WHERE ACC_TYPE = t.ACC_TYPE AND ACC_SUBTYPE = ISNULL(t.ACC_SUBTYPE, -1) AND (ISO IS NULL OR ISO = t.ISO) AND USE_OVERDRAFT = @use_overdraft)

			OPEN cr

			FETCH NEXT FROM cr INTO @_acc_id
			WHILE(@@FETCH_STATUS = 0)
			BEGIN
				EXEC dbo.acc_get_usable_amount 
							@acc_id = @_acc_id,
							@usable_amount = @acc_usable_amount out,
							@use_overdraft = @use_overdraft

				/*

				SELECT @acc_usable_amount = @acc_usable_amount - ISNULL(SUM(AMOUNT), 0), @acc_usable_amount_equ = dbo.get_cross_amount(@acc_usable_amount, @_iso, @iso, @date)
				FROM #acc_balance
				WHERE ACC_ID = @_acc_id

				*/
				
				SELECT @acc_usable_amount = @acc_usable_amount - ISNULL(SUM(AMOUNT), 0)
				FROM #acc_balance
				WHERE ACC_ID = @_acc_id

				SET @rate_amount = NULL
				SET @rate_items = NULL
				SET @rate_reverse = NULL

				EXEC dbo.client_sp_get_convert_amount
							@client_no = @client_no,
							@iso1  = @_iso,
							@iso2 = @iso,
							@amount = @acc_usable_amount,
							@new_amount = @acc_usable_amount_equ out,
							@rate_amount = @rate_amount out,
							@rate_items = @rate_items out,
							@reverse = @rate_reverse out,
							@look_buy = 1

				
				IF (@acc_usable_amount_equ <= @debt_amount)
				BEGIN
					SET @amount = @acc_usable_amount
					SET @amount_equ = @acc_usable_amount_equ					
				END
				ELSE
				BEGIN
					--SET @amount = dbo.get_cross_amount(@debt_amount, @iso, @_iso, @date)
					
					EXEC dbo.client_sp_get_convert_amount
							@client_no = @client_no,
							@iso1  = @iso,
							@iso2 = @_iso,
							@amount = @debt_amount,
							@new_amount = @amount out,
							@rate_amount = @rate_amount out,
							@rate_items = @rate_items out,
							@reverse = @rate_reverse out,
							@look_buy = 0
					
					SET @amount_equ = @debt_amount
				END
					
				IF (@amount > 0 AND @amount_equ > 0)
				BEGIN					
					INSERT INTO #acc_balance 
					VALUES(@priority, @_acc_id, @_iso, @amount, @amount_equ, @acc_type, @acc_subtype, @rate_amount, @rate_items, @rate_reverse, NULL)

					SET @priority = @priority + 1
					SET @debt_amount = @debt_amount - @amount_equ

					IF (@debt_amount = 0) BREAK
				END						

				FETCH NEXT FROM cr INTO @_acc_id
			END

			CLOSE cr
			DEALLOCATE cr

			IF (@debt_amount = 0) BREAK

			FETCH NEXT FROM priority_list INTO @acc_type, @acc_subtype, @_iso, @use_overdraft
		END

		CLOSE priority_list
		DEALLOCATE priority_list	

		RETURN(0)

	END TRY
	BEGIN CATCH
		DECLARE 
			@message nvarchar(max),
			@severity int,
			@state int,
			@cursor_status smallint
					
		SET @message = ERROR_MESSAGE()
		SET @severity = ERROR_SEVERITY()
		SET @state = ERROR_STATE()

		IF (@state NOT BETWEEN 1 AND 127)
			SET @state = 1

		SET @cursor_status = CURSOR_STATUS('variable', 'cr')
				
		IF (@cursor_status >= -1)
		BEGIN
			IF (@cursor_status >= 0)
				CLOSE cr

			DEALLOCATE cr
		END

		SET @cursor_status = CURSOR_STATUS('variable', 'priority_list')
				
		IF (@cursor_status >= -1)
		BEGIN
			IF (@cursor_status >= 0)
				CLOSE priority_list

			DEALLOCATE priority_list
		END		
				
		RAISERROR(@message, @severity, @state)
		RETURN(1)
	END CATCH


GO
