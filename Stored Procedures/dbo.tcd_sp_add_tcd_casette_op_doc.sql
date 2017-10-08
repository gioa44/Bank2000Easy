SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[tcd_sp_add_tcd_casette_op_doc]
(
	@op_id int,
	@user_id int,	
	@doc_rec_id int OUTPUT
)
AS
BEGIN

	DECLARE @internal_transaction bit
	SET @internal_transaction = 0
	IF @@TRANCOUNT = 0
	BEGIN
		BEGIN TRAN
		SET @internal_transaction = 1
	END

	DECLARE @op_type int,
			@tcd_serial_id varchar(50),
			@tmp_doc_rec_id int,
			@credit_acc_id int,
			@debit_acc_id int,
			@casette_ccy TISO,
			@casette_serial_id int,
			@branch_id int,
			@user_dept_no int,
			@tcd_casette_account TACCOUNT,
			@tcd_account TACCOUNT,
			@kas_acc TACCOUNT,
			@amount money,
			@day_name varchar(20),
			@time1 smalldatetime,
			@time2 smalldatetime,
			@op_date smalldatetime,
			@descrip varchar(50),
			@parent_doc_id int,
			@collection_id int,
			@collector_id int,
			--ცვლადები სალაროს შემოს/გასავლ. საბუთებისთვის
			@first_name varchar(50),
			@last_name varchar(50), 
			@fathers_name varchar(50), 
			@birth_date smalldatetime, 
			@birth_place varchar(100), 
			@address_jur varchar(100), 
			@address_lat varchar(100),
			@country varchar(2), 
			@passport_type_id tinyint,
			@passport varchar(50), 
			@personal_id varchar(20),
			@reg_organ varchar(50),
			@passport_issue_dt smalldatetime,
			@passport_end_date smalldatetime,

			@r int
	
	SET @user_dept_no = dbo.user_dept_no(@user_id)

	SELECT @op_type = OP_TYPE, @op_date = OP_DATE, @collector_id = COLLECTOR_ID, @collection_id = COLLECTION_ID
	FROM dbo.TCD_CASETTE_OPS
	WHERE OP_ID = @op_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('TCD_CASETTE_OPS DATA ERROR' , 16, 1); RETURN (1); END

	SELECT @branch_id = BRANCH_ID, @tcd_serial_id = TCD_SERIAL_ID
	FROM dbo.TCD_CASETTE_COLLECTIONS
	WHERE COLLECTION_ID = @collection_id
	IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('TCD_CASETTE_COLLECTIONS DATA ERROR' , 16, 1); RETURN (1); END
		
	IF @op_type = 2  --კასეტების TCD აპარატში ჩასადებად გაგზავნა
	BEGIN
		SET @parent_doc_id=-1

		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT ISNULL(SUM(CASETTE_DEN*[COUNT]), $0.00) AS AMOUNT, CASETTE_CCY
			FROM dbo.TCD_CASETTE_OP_DETAILS
			WHERE OP_ID = @op_id AND CASETTE_CCY <> '*'
			GROUP BY CASETTE_CCY

		OPEN cc
		FETCH NEXT FROM cc INTO @amount, @casette_ccy
				
		WHILE @@FETCH_STATUS = 0
		BEGIN
			SELECT @tcd_casette_account = CASE WHEN @casette_ccy='GEL' THEN TCD_CASETTE_ACCOUNT ELSE TCD_CASETTE_ACCOUNT_V END
			FROM dbo.DEPTS
			WHERE BRANCH_ID = @branch_id AND IS_DEPT = 0
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('DEPTS DATA ERROR' , 16, 1); RETURN (1); END
			SET @debit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_casette_account, @casette_ccy)
			
			IF @casette_ccy = 'GEL'
			BEGIN
				EXEC dbo.GET_CASHIER_ACC
					@dept_id = @user_dept_no,
					@user_id = @user_id,
					@param_name = 'KAS_ACC',
					@acc = @kas_acc OUTPUT
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('CASHIER ACCOUNT NOT FOUND' , 16, 1); RETURN (1); END
			END
			ELSE
			BEGIN
				EXEC dbo.GET_CASHIER_ACC	
					@dept_id = @user_dept_no,
					@user_id = @user_id,
					@param_name = 'KAS_ACC_V',
					@acc = @kas_acc OUTPUT
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('CASHIER ACCOUNT NOT FOUND' , 16, 1); RETURN (1); END
			END
			SET @credit_acc_id = dbo.acc_get_acc_id(dbo.user_branch_id(@user_id), @kas_acc, @casette_ccy)



			SELECT 	@first_name = C.FIRST_NAME, @last_name = C.LAST_NAME, @fathers_name= C.FATHERS_NAME, @birth_date = C.BIRTH_DATE, @birth_place= C.BIRTH_PLACE, 
					@address_jur= dbo.cli_get_cli_attribute(@collector_id, '$ADDRESS_LEGAL'), 
					@address_lat= dbo.cli_get_cli_attribute(@collector_id, '$ADDRESS_LAT'),
					@country = C.COUNTRY,@passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id= PERSONAL_ID, @reg_organ = REG_ORGAN,
					@passport_issue_dt= PASSPORT_ISSUE_DT, @passport_end_date= PASSPORT_END_DATE
			FROM dbo.CLIENTS C
			WHERE C.CLIENT_NO = @collector_id

			SET @descrip = 'ÓÀËÀÒÏÃÀÍ TCD ÀÐÀÒÀÔÉÓ ÊÀÓÄÔÀÛÉ ×ÖËÉÓ ÜÀÃÄÁÀ/ÊÀÓÄÔÄÁÉÓ TCD ÀÐÀÒÀÔÛÉ ÜÀÓÀÃÄÁÀÃ ÂÀÂÆÀÅÍÀ'
			EXEC @r = dbo.ADD_DOC4
				@rec_id =  @tmp_doc_rec_id OUTPUT,
				@user_id = @user_id,
				@doc_type = 130,  --Cash Order სალაროდან კასეტაში ფულის ჩადება. გასავალი
				@doc_date = @op_date,
				@debit_id = @debit_acc_id,
				@credit_id = @credit_acc_id,
				@iso = @casette_ccy, 
				@amount = @amount,
				@rec_state = 0, -- წითელი ავტორიზაცია
				@descrip = @descrip,
				@op_code = 0, -- @op_code
				@dept_no = @user_dept_no,
				@channel_id = 60,
				@parent_rec_id = @parent_doc_id,
				@flags = 1,
				@cashier = @user_id,
				@first_name = @first_name,
				@last_name = @last_name,
				@fathers_name = @fathers_name,
				@birth_date = @birth_date,
				@birth_place = @birth_place,
				@address_jur = @address_jur,
				@address_lat = @address_lat,
				@country = @country,
				@passport_type_id = @passport_type_id,
				@passport = @passport,
				@personal_id = @personal_id,
				@reg_organ = @reg_organ,
				@passport_issue_dt = @passport_issue_dt,
				@passport_end_date = @passport_end_date
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END	

			IF @parent_doc_id = -1
			BEGIN
				SET @doc_rec_id = @tmp_doc_rec_id
				SET @parent_doc_id = @doc_rec_id
			END

			FETCH NEXT FROM cc INTO @amount, @casette_ccy
		END
		CLOSE cc
		DEALLOCATE cc
	END
	ELSE IF @op_type = 3  --TCD აპარატიდან კასეტების ამოღება
	BEGIN		
		
		SET @parent_doc_id=-1
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CASETTE_CCY
			FROM dbo.TCD_VW_CASETTES_IN_TCD		
			WHERE TCD_SERIAL_ID = @tcd_serial_id AND (CASETTE_CCY IS NOT NULL) AND (CASETTE_CCY <> '*')
			GROUP BY CASETTE_CCY

		OPEN cc
		FETCH NEXT FROM cc INTO @casette_ccy
				
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--@debit_acc_id - ის განსაზღვრა
			SELECT @tcd_casette_account = CASE WHEN @casette_ccy='GEL' THEN TCD_CASETTE_ACCOUNT ELSE TCD_CASETTE_ACCOUNT_V END
			FROM dbo.DEPTS
			WHERE BRANCH_ID = @branch_id AND IS_DEPT = 0
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('DEPTS DATA ERROR' , 16, 1); RETURN (1); END
			SET @debit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_casette_account, @casette_ccy)		
			--@credit_acc_id - ის განსაზღვრა
			SELECT	@tcd_account = CASE WHEN @casette_ccy='GEL' THEN ACCOUNT ELSE ACCOUNT_V END
			FROM dbo.TCDS
			WHERE TCD_SERIAL_ID = @tcd_serial_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('TCDS DATA ERROE' , 16, 1); RETURN (1); END
			
			SET @credit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_account, @casette_ccy)
			SET @amount = dbo.acc_get_balance(@credit_acc_id, '2079-01-01 00:00:00.000', 0, 0, 2)
			IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('GET TCD BALANCE ERROR' , 16, 1); RETURN (1); END

			IF @amount <> 0
			BEGIN
				SET @descrip = 'TCD ÀÐÀÒÀÔÉÃÀÍ ÊÀÓÄÔÄÁÉÓ ÀÌÏÙÄÁÀ'
				EXEC @r = dbo.ADD_DOC4
					@rec_id = @tmp_doc_rec_id OUTPUT,
					@user_id = @user_id,
					@doc_type = 98,  --memo Order TCD აპარატიდან კასეტების ამოღება
					@doc_date = @op_date,
					@debit_id = @debit_acc_id,
					@credit_id = @credit_acc_id,
					@iso = @casette_ccy, 
					@amount = @amount,
					@rec_state = 0, --წითელი ავტორიზაცია
					@descrip = @descrip,
					@op_code = 0, --@op_code
					@dept_no = @user_dept_no,
					@channel_id = 60,
					@parent_rec_id = @parent_doc_id,
					@flags = 1
				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
			
				IF @parent_doc_id = -1
				BEGIN
					SET @doc_rec_id = @tmp_doc_rec_id
					SET @parent_doc_id = @doc_rec_id
				END
			END

			FETCH NEXT FROM cc INTO @casette_ccy
		END
		CLOSE cc
		DEALLOCATE cc
	END	
	ELSE IF @op_type = 4  --TCD აპარატში კასეტების ჩადება
	BEGIN		
		
		SET @parent_doc_id=-1
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT SUM(CASETTE_DEN*[COUNT]) AS AMOUNT, CASETTE_CCY
			FROM dbo.TCD_CASETTE_OP_DETAILS
			WHERE OP_ID = @op_id AND CASETTE_CCY <> '*'
			GROUP BY CASETTE_CCY, OP_ID


		OPEN cc
		FETCH NEXT FROM cc INTO @amount, @casette_ccy
				
		WHILE @@FETCH_STATUS = 0
		BEGIN
			--@credit_acc_id
			SELECT @tcd_casette_account = CASE WHEN @casette_ccy='GEL' THEN TCD_CASETTE_ACCOUNT ELSE TCD_CASETTE_ACCOUNT_V END
			FROM dbo.DEPTS
			WHERE BRANCH_ID = @branch_id AND IS_DEPT = 0
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('DEPTS DATA ERROR' , 16, 1); RETURN (1); END
			SET @credit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_casette_account, @casette_ccy)
			
			--@debit_acc_id
			SELECT	@tcd_account = CASE WHEN @casette_ccy='GEL' THEN ACCOUNT ELSE ACCOUNT_V END
			FROM dbo.TCDS
			WHERE TCD_SERIAL_ID = @tcd_serial_id
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('TCDS DATA ERROR' , 16, 1); RETURN (1); END
			SET @debit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_account, @casette_ccy)

			SET @descrip = 'TCD ÀÐÀÒÀÔÛÉ ÊÀÓÄÔÄÁÉÓ ÜÀÃÄÁÀ'
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @tmp_doc_rec_id OUTPUT,
				@user_id = @user_id,
				@doc_type = 98,  --memo Order TCD აპარატში კასეტების ჩადება
				@doc_date = @op_date,
				@debit_id = @debit_acc_id,
				@credit_id = @credit_acc_id,
				@iso = @casette_ccy, 
				@amount = @amount,
				@rec_state = 0, -- წითელი ავტორიზაცია
				@descrip = @descrip,
				@op_code = 0, -- @op_code
				@dept_no = @user_dept_no,
				@channel_id = 60,
				@parent_rec_id = @parent_doc_id,
				@flags = 1
			IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END
			
			IF @parent_doc_id = -1
			BEGIN
				SET @doc_rec_id = @tmp_doc_rec_id
				SET @parent_doc_id = @doc_rec_id
			END

			FETCH NEXT FROM cc INTO @amount, @casette_ccy
		END
		CLOSE cc
		DEALLOCATE cc
	END	
	ELSE IF @op_type = 5 --კასეტებიდან ფულის ამოღება
	BEGIN
		DECLARE 
			@op_doc_rec_id int,
			@op_date2 smalldatetime,
			@unknown_acc_id int,
			@doc_amount money,
			@unknown_account TACCOUNT

		SET @parent_doc_id=-1		

		DECLARE @tbl TABLE(CCY varchar(3) NOT NULL PRIMARY KEY, AMOUNT money)
		
		SELECT @op_doc_rec_id = DOC_REC_ID, @op_date2 = OP_DATE
		FROM dbo.TCD_CASETTE_OPS
		WHERE COLLECTION_ID = @collection_id AND OP_TYPE = 3
		
		IF @op_date2 < dbo.bank_open_date() 
		BEGIN			
			INSERT INTO @tbl
			SELECT ISO, AMOUNT 
			FROM dbo.DOCS_ARC_ALL DA (NOLOCK) 
			WHERE (DA.REC_ID = @op_doc_rec_id OR DA.PARENT_REC_ID = @op_doc_rec_id)
		END
		ELSE 
		BEGIN
			INSERT INTO @tbl
			SELECT ISO, AMOUNT 
			FROM dbo.DOCS_ALL DA (NOLOCK)
			WHERE (DA.REC_ID = @op_doc_rec_id OR DA.PARENT_REC_ID = @op_doc_rec_id)
		END

		--კურსორი
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT ISNULL(SUM(CASETTE_DEN*[COUNT]), $0.00) AS AMOUNT, CASETTE_CCY
			FROM dbo.TCD_CASETTE_OP_DETAILS
			WHERE OP_ID = @op_id AND CASETTE_CCY <> '*'
			GROUP BY CASETTE_CCY

		OPEN cc
		FETCH NEXT FROM cc INTO @amount, @casette_ccy
				
		WHILE @@FETCH_STATUS = 0
		BEGIN

			SET @doc_amount = @amount
			
			SELECT @doc_amount = SUM(AMOUNT)
			FROM @tbl
			WHERE CCY = @casette_ccy
			GROUP BY CCY
						
			SELECT @tcd_casette_account = CASE WHEN @casette_ccy='GEL' THEN TCD_CASETTE_ACCOUNT ELSE TCD_CASETTE_ACCOUNT_V END
			FROM dbo.DEPTS
			WHERE BRANCH_ID = @branch_id AND IS_DEPT = 0
			IF @@ERROR <> 0 OR @@ROWCOUNT <> 1 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('DEPTS DATA ERROR' , 16, 1); RETURN (1); END
			SET @credit_acc_id = dbo.acc_get_acc_id(@branch_id, @tcd_casette_account, @casette_ccy)

			IF @casette_ccy = 'GEL'			
			BEGIN
				EXEC dbo.GET_CASHIER_ACC	
					@dept_id = @user_dept_no,
					@user_id = @user_id,
					@param_name = 'KAS_ACC',
					@acc = @kas_acc OUTPUT
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('CASHIER ACCOUNT NOT FOUND' , 16, 1); RETURN (1); END
			END
			ELSE
			BEGIN
				EXEC dbo.GET_CASHIER_ACC	
					@dept_id = @user_dept_no,
					@user_id = @user_id,
					@param_name = 'KAS_ACC_V',
					@acc = @kas_acc OUTPUT
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('CASHIER ACCOUNT NOT FOUND' , 16, 1); RETURN (1); END
			END
			SET @debit_acc_id = dbo.acc_get_acc_id(dbo.user_branch_id(@user_id), @kas_acc, @casette_ccy)
		


			SELECT 	@first_name = C.FIRST_NAME, @last_name = C.LAST_NAME, @fathers_name= C.FATHERS_NAME, @birth_date = C.BIRTH_DATE, @birth_place= C.BIRTH_PLACE, 
					@address_jur= dbo.cli_get_cli_attribute(@collector_id, '$ADDRESS_LEGAL'), 
					@address_lat= dbo.cli_get_cli_attribute(@collector_id, '$ADDRESS_LAT'),
					@country = C.COUNTRY,@passport_type_id = PASSPORT_TYPE_ID, @passport = PASSPORT, @personal_id= PERSONAL_ID, @reg_organ = REG_ORGAN,
					@passport_issue_dt= PASSPORT_ISSUE_DT, @passport_end_date= PASSPORT_END_DATE
			FROM dbo.CLIENTS C
			WHERE C.CLIENT_NO = @collector_id

			SET @descrip = 'TCD ÀÐÀÒÀÔÉÓ ÊÀÓÄÔÉÃÀÍ ÓÀËÀÒÏÛÉ ×ÖËÉÓ ÃÀÁÒÖÍÄÁÀ'
			IF @amount <> 0
			BEGIN
				EXEC @r = dbo.ADD_DOC4
					@rec_id =  @tmp_doc_rec_id OUTPUT,
					@user_id = @user_id,
					@doc_type = 120,  --Cash Order კასეტიდან სალაროში ფულის დაბრუნება. შემოსავალი
					@doc_date = @op_date,
					@debit_id = @debit_acc_id,
					@credit_id = @credit_acc_id,
					@iso = @casette_ccy, 
					@amount = @amount,
					@rec_state = 0, -- წითელი ავტორიზაცია
					@descrip = @descrip,
					@op_code = 0, -- @op_code
					@dept_no = @user_dept_no,
					@channel_id = 60,
					@parent_rec_id = @parent_doc_id,
					@flags = 1,
					@cashier = @user_id,
					@first_name = @first_name,
					@last_name = @last_name,
					@fathers_name = @fathers_name,
					@birth_date = @birth_date,
					@birth_place = @birth_place,
					@address_jur = @address_jur,
					@address_lat = @address_lat,
					@country = @country,
					@passport_type_id = @passport_type_id,
					@passport = @passport,
					@personal_id = @personal_id,
					@reg_organ = @reg_organ,
					@passport_issue_dt = @passport_issue_dt,
					@passport_end_date = @passport_end_date
				IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END	

				IF @parent_doc_id = -1
				BEGIN
					SET @doc_rec_id = @tmp_doc_rec_id
					SET @parent_doc_id = @doc_rec_id
				END
			END
			
			IF @amount <> @doc_amount
			BEGIN				
				IF @amount < @doc_amount
				BEGIN
					SELECT @unknown_account = CASE WHEN @casette_ccy='GEL' THEN UNKNOWN_ACCOUNT1 ELSE UNKNOWN_ACCOUNT1_V END
					FROM dbo.TCDS
					WHERE TCD_SERIAL_ID = @tcd_serial_id

					SET @unknown_acc_id = dbo.acc_get_acc_id(@branch_id, @unknown_account, @casette_ccy)
					SET @doc_amount = @doc_amount - @amount

					SET @descrip = 'ÂÀÖÒÊÅÄÅÄË ÀÍÂÀÒÉÛÆÄ TCD ÀÐÀÒÀÔÉÃÀÍ ÃÀÁÒÖÍÄÁÖËÉ ÈÀÍáÉÓ ÍÀÊËÄÁÏÁÉÓ ÊÏÒÄØÔÉÒÄÁÀ'
					EXEC @r = dbo.ADD_DOC4
						@rec_id = @tmp_doc_rec_id OUTPUT,
						@user_id = @user_id,
						@doc_type = 98,  --memo Order გაურკვეველ ანგარიშზე ფულის დასმა
						@doc_date = @op_date,
						@debit_id = @unknown_acc_id,
						@credit_id = @credit_acc_id,
						@iso = @casette_ccy, 
						@amount = @doc_amount,
						@rec_state = 0, -- წითელი ავტორიზაცია
						@descrip = @descrip,
						@op_code = 0, -- @op_code
						@dept_no = @user_dept_no,
						@channel_id = 60,
						@parent_rec_id = @parent_doc_id,
						@flags = 1
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END

					IF @parent_doc_id = -1
					BEGIN
						SET @doc_rec_id = @tmp_doc_rec_id
						SET @parent_doc_id = @doc_rec_id
					END

				END
				ELSE
				BEGIN
					SELECT @unknown_account = CASE WHEN @casette_ccy='GEL' THEN UNKNOWN_ACCOUNT2 ELSE UNKNOWN_ACCOUNT2_V END
					FROM dbo.TCDS
					WHERE TCD_SERIAL_ID = @tcd_serial_id

					SET @unknown_acc_id = dbo.acc_get_acc_id(@branch_id, @unknown_account, @casette_ccy)
					SET @doc_amount = @amount - @doc_amount

					SET @descrip = 'ÂÀÖÒÊÅÄÅÄË ÀÍÂÀÒÉÛÆÄ TCD ÀÐÀÒÀÔÉÃÀÍ ÃÀÁÒÖÍÄÁÖËÉ ÈÀÍáÉÓ ÌÄÔÏÁÉÓ ÊÏÒÄØÔÉÒÄÁÀ'
					EXEC @r = dbo.ADD_DOC4
						@rec_id = @tmp_doc_rec_id OUTPUT,
						@user_id = @user_id,
						@doc_type = 98,  --memo Order გაურკვეველ ანგარიშზე ფულის დასმა
						@doc_date = @op_date,
						@debit_id = @credit_acc_id,
						@credit_id = @unknown_acc_id,
						@iso = @casette_ccy, 
						@amount = @doc_amount,
						@rec_state = 0,
						@descrip = @descrip,
						@op_code = 0,
						@dept_no = @user_dept_no,
						@channel_id = 60,
						@parent_rec_id = @parent_doc_id,
						@flags = 1
					IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 ROLLBACK; RAISERROR ('ERROR ADD DOCUMENT' , 16, 1); RETURN (1); END

					IF @parent_doc_id = -1
					BEGIN
						SET @doc_rec_id = @tmp_doc_rec_id
						SET @parent_doc_id = @doc_rec_id
					END

				END
			END

			FETCH NEXT FROM cc INTO @amount, @casette_ccy
		END
		CLOSE cc
		DEALLOCATE cc
	END
		
	IF @internal_transaction = 1
		COMMIT
	RETURN 0
END
GO
