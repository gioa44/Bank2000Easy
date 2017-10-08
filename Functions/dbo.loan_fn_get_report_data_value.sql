SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[loan_fn_get_report_data_value](@loan_id int, @param_name varchar(max), @is_lat bit)
RETURNS varchar(8000)
AS
BEGIN
	DECLARE
		@result varchar(1500),
		@disburse_type int,
		@purpose_type int,
		@counter int,
		@client_type int,
		@loan_collateral_type varchar(50),
		@loan_collateral_descrip varchar(200),
		@depo_collateral_accounts varchar(200),
		@loan_coborrowers_descrip varchar(200),
		@personal_id varchar(20),
		@passport varchar(50),
		@phone1 varchar(61),
		@attrib_value varchar(200),
		@attrib_value2 varchar(200),
		@passport_issue_dt smalldatetime, 
		@passport_reg_organ varchar(50),
		@coborrowers_account varchar(50),
		@coborrowers_account_v varchar(50),
		@reg_organ varchar(50),
		@reg_date varchar(20),
		@tax_insp_code varchar(11),
		@credit_line_id int,
		@credit_line_star_date int

	SET @result = '';

	SELECT @disburse_type = DISBURSE_TYPE, @purpose_type = PURPOSE_TYPE, @credit_line_id = CREDIT_LINE_ID
	FROM dbo.LOANS (NOLOCK)
	WHERE LOAN_ID = @loan_id

	IF @param_name = 'DEPO_ACCOUNTS'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CONVERT(varchar(20), AC.ACCOUNT) + '/' + AC.ISO
			FROM dbo.LOAN_COLLATERALS (NOLOCK) LC
			INNER JOIN dbo.ACCOUNTS AC (NOLOCK) ON AC.ACC_ID = LC.COLLATERAL_DETAILS.value('(row/@ACC_ID)[1]', 'int')
			WHERE COLLATERAL_TYPE = 2 AND LOAN_ID = @loan_id
			
		SET @result = ''
		SET @depo_collateral_accounts = ''
		SET @counter = 1	

		OPEN cc
		FETCH NEXT FROM cc INTO @depo_collateral_accounts

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @result = @result + '    1.' + CONVERT(varchar(3), @counter) + ' ' + @depo_collateral_accounts + CHAR(13)

			SET @counter = @counter + 1
			FETCH NEXT FROM cc INTO @depo_collateral_accounts
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'DEPO_ACCOUNTS2'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CONVERT(varchar(20), AC.ACCOUNT) + '/' + AC.ISO
			FROM dbo.LOAN_COLLATERALS (NOLOCK) LC
			INNER JOIN dbo.ACCOUNTS AC (NOLOCK) ON AC.ACC_ID = LC.COLLATERAL_DETAILS.value('(row/@ACC_ID)[1]', 'int')
			WHERE COLLATERAL_TYPE = 2 AND LOAN_ID = @loan_id

		SET @result = ''
		SET @depo_collateral_accounts = ''
		SET @counter = 1	

		OPEN cc
		FETCH NEXT FROM cc INTO @depo_collateral_accounts

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @result = @result + @depo_collateral_accounts + '; '

			SET @counter = @counter + 1
			FETCH NEXT FROM cc INTO @depo_collateral_accounts
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'COLLATERALS'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT DESCRIP
			FROM dbo.LOAN_COLLATERALS (NOLOCK)
			WHERE LOAN_ID = @loan_id

		SET @result = ''
		SET @loan_collateral_descrip = ''
		SET @counter = 1	

		OPEN cc
		FETCH NEXT FROM cc INTO @loan_collateral_descrip

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @result = @result + '    1.' + CONVERT(varchar(3), @counter) + ' ' + @loan_collateral_descrip + CHAR(13)

			SET @counter = @counter + 1
			FETCH NEXT FROM cc INTO @loan_collateral_descrip
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'COLLATERALS2'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT LCT.DESCRIP, C.DESCRIP
			FROM dbo.LOAN_COLLATERALS (NOLOCK) LC
				INNER JOIN dbo.CLIENTS (NOLOCK) C ON C.CLIENT_NO = LC.CLIENT_NO
				INNER JOIN dbo.LOAN_COLLATERAL_TYPES (NOLOCK) LCT ON LCT.[TYPE_ID] = LC.COLLATERAL_TYPE
			WHERE LOAN_ID = @loan_id

		SET @result = ''
		SET @loan_collateral_descrip = ''
		SET @counter = 1	

		OPEN cc
		FETCH NEXT FROM cc INTO @loan_collateral_type, @loan_collateral_descrip

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @result = @result + '    1.' + CONVERT(varchar(3), @counter) + ' ' + @loan_collateral_type + '--' + @loan_collateral_descrip + CHAR(13)

			SET @counter = @counter + 1
			FETCH NEXT FROM cc INTO @loan_collateral_type, @loan_collateral_descrip
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'DISBURSE_TYPE'
	BEGIN
		IF @is_lat = 0
		BEGIN
			IF @disburse_type = 1
				SET @result = 'ÄÒÈãÄÒÀÃÀÃ'
			ELSE IF @disburse_type = 2
				SET @result = 'ÌÒÀÅÀËãÄÒÀÃÀÃ'
			ELSE IF @disburse_type = 4
				SET @result = 'ÒÄÅÏËÅÉÒÄÁÀÃÀÃ'
		END
		ELSE
		BEGIN
			IF @disburse_type = 1
				SET @result = 'SINGLE'
			ELSE IF @disburse_type = 2
				SET @result = 'MULTIPLE'
			ELSE IF @disburse_type = 4
				SET @result = 'REVOLVE'
		END
	END
	ELSE
	IF @param_name = 'DISBURSE_TYPE2'
	BEGIN
		IF @is_lat = 0
		BEGIN
			IF @disburse_type = 1
				SET @result = 'ÄÒÈãÄÒÀÃÀÃ'
			ELSE IF @disburse_type = 2
				SET @result = 'ÔÒÀÍÛÄÁÀÃ, ÓÀÊÒÄÃÉÔÏ áÀÆÉÓ ÓÀáÉÈ'
			ELSE IF @disburse_type = 4
				SET @result = 'ÒÄÅÏËÅÉÒÄÁÀÃÀÃ'
		END
		ELSE
		BEGIN
			IF @disburse_type = 1
				SET @result = 'SINGLE'
			ELSE IF @disburse_type = 2
				SET @result = 'MULTIPLE'
			ELSE IF @disburse_type = 4
				SET @result = 'REVOLVE'
		END
	END
	ELSE
	IF @param_name = 'DISBURSE_TYPE3'
	BEGIN
		IF @is_lat = 0
		BEGIN
			IF @disburse_type = 1
				SET @result = 'ÄÒÈãÄÒÀÃÀÃ'
			ELSE IF @disburse_type = 2
				SET @result = 'ÔÒÀÍÛÄÁÀÃ, ÓÀÊÒÄÃÉÔÏ áÀÆÉÓ ÓÀáÉÈ'
			ELSE IF @disburse_type = 4
				SET @result = 'ÔÒÀÍÛÄÁÀÃ, ÒÄÅÏËÅÄÒÖËÉ ÓÀÊÒÄÃÉÔÏ áÀÆÉÓ ÓÀáÉÈ'
		END
		ELSE
		BEGIN
			IF @disburse_type = 1
				SET @result = 'SINGLE'
			ELSE IF @disburse_type = 2
				SET @result = 'MULTIPLE'
			ELSE IF @disburse_type = 4
				SET @result = 'REVOLVE'
		END
	END
	ELSE
	IF @param_name = 'PURPOSE_TYPE'
	BEGIN
		SELECT @result = CASE WHEN @is_lat = 0 THEN DESCRIP ELSE DESCRIP_LAT END
		FROM dbo.LOAN_PURPOSE_TYPES (NOLOCK)
		WHERE TYPE_ID = @purpose_type
	END
	ELSE
	IF @param_name = 'CLIENTS'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END
			FROM dbo.LOANS L
				INNER JOIN dbo.CLIENTS (NOLOCK) C ON C.CLIENT_NO = L.CLIENT_NO
			WHERE LOAN_ID = @loan_id
			UNION ALL
			SELECT CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END
			FROM dbo.LOAN_VW_LOAN_COBORROWERS
			WHERE LOAN_ID = @loan_id

		SET @loan_coborrowers_descrip = ''
		SET @result = ''

		OPEN cc
		FETCH NEXT FROM cc INTO @loan_coborrowers_descrip

		WHILE @@FETCH_STATUS = 0
		BEGIN
			SET @result = @result + @loan_coborrowers_descrip + '; '
			FETCH NEXT FROM cc INTO @loan_coborrowers_descrip
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'JURIDICAL_CLIENT_REPRESENTATOR'
	BEGIN
		SELECT @result = (CA.ATTRIB_VALUE + ' ' + CA2.ATTRIB_VALUE) + 'Ó'
		FROM dbo.LOANS (NOLOCK) L
			LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = L.CLIENT_NO AND CA.ATTRIB_CODE = '$SIGNATURE_1_NAME'
			LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA2 ON CA2.CLIENT_NO = L.CLIENT_NO AND CA2.ATTRIB_CODE = '$SIGNATURE_1_SURNAME'
		WHERE L.LOAN_ID = @loan_id
	END
	ELSE
	IF @param_name = 'CLIENTS_DETAILS'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END,
					C.PERSONAL_ID,
					C.PASSPORT,
					C.PHONE1, 
					C.CLIENT_TYPE,
					CA.ATTRIB_VALUE,
					C.REG_ORGAN, 
					CONVERT(varchar(20), C.REG_DATE),
					C.TAX_INSP_CODE,					
					(CAA.ATTRIB_VALUE + ' ' + CAAA.ATTRIB_VALUE),
					(SELECT TOP 1 CONVERT(varchar(40) , A1.ACCOUNT) + '/' + A1.ISO FROM dbo.ACCOUNTS (NOLOCK) A1 WHERE A1.CLIENT_NO = L.CLIENT_NO AND A1.BAL_ACC_ALT = 3601 AND REC_STATE NOT IN (2, 128) ),
					(SELECT TOP 1 CONVERT(varchar(40) , A2.ACCOUNT) + '/' + A2.ISO FROM dbo.ACCOUNTS (NOLOCK) A2 WHERE A2.CLIENT_NO = L.CLIENT_NO AND A2.BAL_ACC_ALT = 3611 AND REC_STATE NOT IN (2, 128) )
			FROM dbo.LOANS (NOLOCK) L
				INNER JOIN dbo.CLIENTS (NOLOCK) C ON C.CLIENT_NO = L.CLIENT_NO
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = C.CLIENT_NO AND CA.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END 
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAA ON CAA.CLIENT_NO = C.CLIENT_NO AND CAA.ATTRIB_CODE = '$SIGNATURE_1_NAME'
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAAA ON CAAA.CLIENT_NO = C.CLIENT_NO AND CAAA.ATTRIB_CODE = '$SIGNATURE_1_SURNAME' 
			WHERE L.LOAN_ID = @loan_id
			UNION ALL
			SELECT CASE WHEN @is_lat = 1 THEN C2.DESCRIP_LAT ELSE C2.DESCRIP END,
					C2.PERSONAL_ID,
					C2.PASSPORT,
					C2.PHONE1, 
					C2.CLIENT_TYPE,
					CA2.ATTRIB_VALUE,
					C2.REG_ORGAN,
					CONVERT(varchar(20), C2.REG_DATE),
					C2.TAX_INSP_CODE,
					(CAA2.ATTRIB_VALUE + ' ' + CAAA2.ATTRIB_VALUE),
					(SELECT TOP 1 CONVERT(varchar(40) , A1.ACCOUNT) + '/' + A1.ISO FROM dbo.ACCOUNTS (NOLOCK) A1 WHERE A1.CLIENT_NO = LC.CLIENT_NO AND A1.BAL_ACC_ALT = 3601 AND REC_STATE NOT IN (2, 128) ),
					(SELECT TOP 1 CONVERT(varchar(40) , A2.ACCOUNT) + '/' + A2.ISO FROM dbo.ACCOUNTS (NOLOCK) A2 WHERE A2.CLIENT_NO = LC.CLIENT_NO AND A2.BAL_ACC_ALT = 3611 AND REC_STATE NOT IN (2, 128) )
			FROM dbo.LOAN_COBORROWERS (NOLOCK) LC
				INNER JOIN dbo.CLIENTS (NOLOCK) C2 ON C2.CLIENT_NO = LC.CLIENT_NO
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA2 ON CA2.CLIENT_NO = C2.CLIENT_NO AND CA2.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END 
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAA2 ON CAA2.CLIENT_NO = C2.CLIENT_NO AND CAA2.ATTRIB_CODE = '$SIGNATURE_1_NAME'
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAAA2 ON CAAA2.CLIENT_NO = C2.CLIENT_NO AND CAAA2.ATTRIB_CODE = '$SIGNATURE_1_SURNAME' 
			WHERE LC.LOAN_ID = @loan_id

		SET @loan_coborrowers_descrip = ''
		SET @personal_id = ''
		SET @passport = ''
		SET @phone1 = ''
		SET @client_type = 0
		SET @attrib_value = ''
		SET @result = ''

		OPEN cc
		FETCH NEXT FROM cc INTO	@loan_coborrowers_descrip, @personal_id, @passport, @phone1, @client_type,
								@attrib_value, @reg_organ, @reg_date, @tax_insp_code, @attrib_value2,
								@coborrowers_account, @coborrowers_account_v

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @client_type = 1
			BEGIN
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@loan_coborrowers_descrip, '') + CHAR(13)		
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Document ID: ' ELSE 'ÓÀÁÖÈÉÓ #: ' END + ISNULL(@passport, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Accounts Nat:' + ISNULL(@coborrowers_account, '') + '; Foreign:' + ISNULL(@coborrowers_account_v, '') ELSE 'ÀÍÂÀÒÉÛÄÁÉ ÓÀËÀÒÄ: ' + ISNULL(@coborrowers_account, '') + '; ÓÀÅÀËÖÔÏ: ' + ISNULL(@coborrowers_account_v, '') END + CHAR(13)
			END
			ELSE 
			BEGIN
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name: ' ELSE 'ÐÉÒÉÓ ÃÀÓÀáÄËÄÁÀ: ' END + ISNULL(@loan_coborrowers_descrip, '') + CHAR(13)		
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Reg. Organ: ' ELSE 'ÌÀÒÄÂÉÓÔÒ. ÏÒÂÀÍÏ: ' END + ISNULL(@reg_organ, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tax Insp Code: ' ELSE 'ÒÄÂÉÓÔÒÀÝÉÉÓ #: ' END + ISNULL(@tax_insp_code, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Reg. Date: ' ELSE 'ÒÄÂÉÓÔÒÀÝÉÉÓ ÈÀÒÉÙÉ #: ' END + ISNULL(@reg_date, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Representator: ' ELSE 'ßÀÒÌÏÌÀÃÂÄÍÄËÉ: ' END + ISNULL(@attrib_value2, '') + CHAR(13)
			END
			SET @result = @result + CHAR(13)
			FETCH NEXT FROM cc INTO	@loan_coborrowers_descrip, @personal_id, @passport, @phone1, @client_type, 
									@attrib_value, @reg_organ, @reg_date, @tax_insp_code, @attrib_value2,
									@coborrowers_account, @coborrowers_account_v
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'CLIENTS_DETAILS2'
	BEGIN
		DECLARE cc CURSOR LOCAL FAST_FORWARD
		FOR
			SELECT CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END,
					C.PERSONAL_ID,
					C.PASSPORT,
					C.PHONE1, 
					C.CLIENT_TYPE,
					CA.ATTRIB_VALUE,
					C.REG_ORGAN, 
					CONVERT(varchar(20), C.REG_DATE),
					C.TAX_INSP_CODE,					
					(CAA.ATTRIB_VALUE + ' ' + CAAA.ATTRIB_VALUE)
			FROM dbo.LOANS (NOLOCK) L
				INNER JOIN dbo.CLIENTS (NOLOCK) C ON C.CLIENT_NO = L.CLIENT_NO
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = C.CLIENT_NO AND CA.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAA ON CAA.CLIENT_NO = C.CLIENT_NO AND CAA.ATTRIB_CODE = '$SIGNATURE_1_SURNAME'
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAAA ON CAAA.CLIENT_NO = C.CLIENT_NO AND CAAA.ATTRIB_CODE = '$SIGNATURE_1_NAME'
			WHERE L.LOAN_ID = @loan_id
			UNION ALL
			SELECT CASE WHEN @is_lat = 1 THEN C2.DESCRIP_LAT ELSE C2.DESCRIP END,
					C2.PERSONAL_ID,
					C2.PASSPORT,
					C2.PHONE1, 
					C2.CLIENT_TYPE,
					CA2.ATTRIB_VALUE,
					C2.REG_ORGAN,
					CONVERT(varchar(20), C2.REG_DATE),
					C2.TAX_INSP_CODE,
					(CAA2.ATTRIB_VALUE + ' ' + CAAA2.ATTRIB_VALUE)
			FROM dbo.LOAN_COBORROWERS (NOLOCK) LC
				INNER JOIN dbo.CLIENTS (NOLOCK) C2 ON C2.CLIENT_NO = LC.CLIENT_NO
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA2 ON CA2.CLIENT_NO = C2.CLIENT_NO AND CA2.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAA2 ON CAA2.CLIENT_NO = C2.CLIENT_NO AND CAA2.ATTRIB_CODE = '$SIGNATURE_1_SURNAME'
				LEFT JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CAAA2 ON CAAA2.CLIENT_NO = C2.CLIENT_NO AND CAAA2.ATTRIB_CODE = '$SIGNATURE_1_NAME'
			WHERE LC.LOAN_ID = @loan_id

		SET @loan_coborrowers_descrip = ''
		SET @personal_id = ''
		SET @passport = ''
		SET @phone1 = ''
		SET @client_type = 0
		SET @attrib_value = ''
		SET @result = ''

		OPEN cc
		FETCH NEXT FROM cc INTO	@loan_coborrowers_descrip, @personal_id, @passport, @phone1, @client_type, 
								@attrib_value, @reg_organ, @reg_date, @tax_insp_code, @attrib_value2

		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @client_type = 1
			BEGIN
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@loan_coborrowers_descrip, '') + CHAR(13)		
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Document ID: ' ELSE 'ÓÀÁÖÈÉÓ #: ' END + ISNULL(@passport, '') + CHAR(13)
			END
			ELSE 
			BEGIN
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name: ' ELSE 'ÐÉÒÉÓ ÃÀÓÀáÄËÄÁÀ: ' END + ISNULL(@loan_coborrowers_descrip, '') + CHAR(13)		
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Reg. Organ: ' ELSE 'ÌÀÒÄÂÉÓÔÒ. ÏÒÂÀÍÏ: ' END + ISNULL(@reg_organ, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tax Insp Code: ' ELSE 'ÒÄÂÉÓÔÒÀÝÉÉÓ #: ' END + ISNULL(@tax_insp_code, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Reg. Date: ' ELSE 'ÒÄÂÉÓÔÒÀÝÉÉÓ ÈÀÒÉÙÉ #: ' END + ISNULL(@reg_date, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Representator: ' ELSE 'ßÀÒÌÏÌÀÃÂÄÍÄËÉ: ' END + ISNULL(@attrib_value2, '') + CHAR(13)
			END
			SET @result = @result + CHAR(13)
			FETCH NEXT FROM cc INTO	@loan_coborrowers_descrip, @personal_id, @passport, @phone1, @client_type, 
									@attrib_value, @reg_organ, @reg_date, @tax_insp_code, @attrib_value2
		END
		CLOSE cc
		DEALLOCATE cc

		IF LEN(@result) > 0
			SET @result = SUBSTRING(@result, 1, LEN(@result) - 1)
	END
	ELSE
	IF @param_name = 'COBORROWER_NUMBER'
	BEGIN
		SELECT @counter = COUNT(*) + 1
		FROM dbo.LOAN_COBORROWERS (NOLOCK)
		WHERE LOAN_ID = @loan_id
		
		IF @counter = 2
			 SET @result = 'ÏÒÉÅÄ'
		ELSE IF @counter = 3
			 SET @result = 'ÓÀÌÉÅÄ'
		ELSE IF @counter = 4
			 SET @result = 'ÏÈáÉÅÄ'
		ELSE IF @counter = 5
			 SET @result = 'áÖÈÉÅÄ'
	END
	ELSE
	IF @param_name = 'CREDIT_LINE_START_DATE'
	BEGIN
		SELECT @result = CONVERT(varchar(50), [START_DATE], 103) 
		FROM dbo.LOAN_CREDIT_LINES
		WHERE CREDIT_LINE_ID = @credit_line_id
	END
	IF @param_name = 'CUSTPRM_1'
	BEGIN
		SET @result = 'TEST'
		RETURN(@result)
	END
	ELSE
	IF @param_name = 'LOAN_COMMENT'
	BEGIN
		SELECT @result = DESCRIP
		FROM dbo.LOAN_DATA (NOLOCK)
		WHERE LOAN_ID = @loan_id
	END

	RETURN @result
END
GO
