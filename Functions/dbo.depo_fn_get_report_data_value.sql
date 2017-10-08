SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[depo_fn_get_report_data_value](@depo_id int, @param_name varchar(max), @is_lat bit)
RETURNS varchar(1500)
AS
BEGIN
		
	DECLARE
		@result varchar(1500)

	DECLARE --DEPO DATA
		@dept_no int,
		@client_no int,
		@trust_deposit bit,
		@trust_client_no int,
		@trust_extra_info varchar(255),
		@prod_id int,
		@iso varchar(3),
		@convertible bit,
		@prolongable bit,
		@renewable bit,
		@renew_capitalized bit,
		@shareable bit,
		@shared_control_client_no int,
		@shared_control bit,
		@child_deposit bit,
		@child_control_owner bit,
		@child_control_client_no_1 int,
		@child_control_client_no_2 int,
		@accumulative bit,
		@spend bit,
		@depo_realize_schema int,
		@realize_type int,
		@realize_count int,
		@realize_count_type int,
		@depo_acc_id int,
		@depo_realize_acc_id int,
		@interest_realize_acc_id int,
		@interest_realize_adv_acc_id int
	
	DECLARE --ÃÀÌáÌÀÒÄ ÝÅËÀÃÄÁÉ
		@acc_type int,
		@str0 varchar(150), 
		@str1 varchar(150), 
		@str2 varchar(150),	
		@str3 varchar(150)

	DECLARE -- ÈÀÍÀÌ×ËÏÁÄËÉ ÌÄÀÍÀÁÒÄÄÁÉÓ Descrip-ÄÁÉ
		@descr varchar(50),
		@shr_cli_descr varchar(50),
		@chld_cli_descr_1 varchar(50),
		@chld_cli_descr_2 varchar(50)

	DECLARE --ÌÄÀÍÀÁÒ(ÄÄÁ)ÉÓ ÒÄÊÅÉÆÉÔÄÁÉ
		@personal_id varchar(20),
		@phone1 varchar(61),
		@attrib_value varchar(200),
		@passport varchar(50),
		@passport_issue_dt smalldatetime, 
		@passport_reg_organ varchar(50)

	SET @result = '';

	SELECT @dept_no = DEPT_NO, @client_no = CLIENT_NO, @trust_deposit = TRUST_DEPOSIT, @trust_client_no = TRUST_CLIENT_NO, 
		@trust_extra_info = TRUST_EXTRA_INFO, @prod_id = PROD_ID, @iso = ISO, @convertible = CONVERTIBLE,
		@prolongable = PROLONGABLE, @renewable = RENEWABLE, @renew_capitalized = RENEW_CAPITALIZED, @shareable = SHAREABLE, 
		@shared_control_client_no = SHARED_CONTROL_CLIENT_NO, @shared_control = SHARED_CONTROL, @child_deposit = CHILD_DEPOSIT, 
		@child_control_owner = CHILD_CONTROL_OWNER, @child_control_client_no_1 = CHILD_CONTROL_CLIENT_NO_1,		
		@child_control_client_no_2 = CHILD_CONTROL_CLIENT_NO_2, @accumulative = ACCUMULATIVE, @spend = SPEND,

		@depo_realize_schema = DEPO_REALIZE_SCHEMA, @realize_type = REALIZE_TYPE, @realize_count = REALIZE_COUNT, @realize_count_type = REALIZE_COUNT_TYPE,

		@depo_acc_id = DEPO_ACC_ID, @depo_realize_acc_id = DEPO_REALIZE_ACC_ID, @interest_realize_acc_id = INTEREST_REALIZE_ACC_ID,
		@interest_realize_adv_acc_id = INTEREST_REALIZE_ADV_ACC_ID
	FROM dbo.DEPO_DEPOSITS (NOLOCK)
	WHERE DEPO_ID = @depo_id

	IF @param_name = 'IUR_CLIENT_REPRESENTATOR'
	BEGIN
		SELECT @result = ATTRIB_VALUE FROM CLIENT_ATTRIBUTES WHERE CLIENT_NO = @client_no
		AND ATTRIB_CODE = '$SIGNATURE_1_NAME'		
		
		RETURN(@result)
	END

	IF @param_name = 'CLIENTS'
	BEGIN
		SELECT	@descr = CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END, 
				@shr_cli_descr = CASE WHEN @is_lat = 1 THEN C0.DESCRIP_LAT ELSE C0.DESCRIP END
		FROM DEPO_DEPOSITS DD
			LEFT JOIN dbo.CLIENTS C  ON  C.CLIENT_NO = DD.CLIENT_NO
			LEFT JOIN dbo.CLIENTS C0 ON C0.CLIENT_NO = DD.SHARED_CONTROL_CLIENT_NO
		WHERE DD.DEPO_ID = @depo_id

		SET @result = ISNULL(@descr, '')

		IF ISNULL(@shr_cli_descr, '') <> ''
		SET @result = @result + ', ' + LTRIM(RTRIM(@shr_cli_descr))

		IF ISNULL(@chld_cli_descr_1, '') <> ''
		SET @result = @result + ', ' + LTRIM(RTRIM(@chld_cli_descr_1))

		IF ISNULL(@chld_cli_descr_2, '') <> ''
		SET @result = @result + ', ' + LTRIM(RTRIM(@chld_cli_descr_2))

		RETURN(@result)
    END

	IF @param_name = 'CLIENT_PASSPORT_DETAIL'
	BEGIN
		SELECT @str0 = CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END, @passport = PASSPORT, @personal_id = PERSONAL_ID, @passport_issue_dt = PASSPORT_ISSUE_DT, @passport_reg_organ = PASSPORT_REG_ORGAN 
		FROM CLIENTS
		WHERE CLIENT_NO = @client_no
		
		SET @passport_issue_dt = convert(smalldatetime,floor(convert(real, @passport_issue_dt)))
		
		IF @is_lat = 1
			SET @result = @str0 + ' (Burth Certificate N ' + ISNULL(@passport, '') + ', Place of issue ' + ISNULL(@passport_reg_organ, '') +  ', Date of Issue ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'
		ELSE
			SET @result = @str0 + ' (ÃÀÁÀÃÄÁÉÓ ÌÏßÌÏÁÀ N ' + ISNULL(@passport, '') + ', ÂÀÝ. ÀÃÂÉËÉ ' + ISNULL(@passport_reg_organ, '') +  ', ÂÀÝ. ÈÀÒÉÙÉ ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'

	END

	IF @param_name = 'DEPOSITOR'
	BEGIN		
		IF (@shareable = 1)
			SET @result = CASE WHEN @is_lat = 1 THEN 'Depositors' ELSE 'ÌÄÀÍÀÁÒÄÄÁÉ' END
		ELSE
			SET @result = CASE WHEN @is_lat = 1 THEN 'Depositor' ELSE 'ÌÄÀÍÀÁÒÄ' END
		RETURN(@result)
	END

	IF @param_name = 'DEPOSITOR_REPRESENTATIVE'
	BEGIN		
		IF (@child_control_client_no_2 IS NOT NULL)
			SET @result = CASE WHEN @is_lat = 1 THEN 'Representatives' ELSE 'ßÀÒÌÏÌÀÃÂÄÍËÄÁÉ' END
		ELSE
			SET @result = CASE WHEN @is_lat = 1 THEN 'Representative' ELSE 'ßÀÒÌÏÌÀÃÂÄÍÄËÉ' END
		RETURN(@result)
	END	

	IF @param_name = 'DEPO_ACCOUNT'
	BEGIN	
		SET @result = CONVERT(varchar(1000), dbo.acc_get_account(@depo_acc_id))
	END

	IF @param_name = 'DEPO_REALIZE_ACCOUNT'
	BEGIN	
		SET @result = CONVERT(varchar(1000), dbo.acc_get_account(@depo_realize_acc_id))
	END	

	IF @param_name = 'DEPO_REALIZE_ACCOUNT_TYPE'
	BEGIN
		SELECT @acc_type = AT.ACC_TYPE FROM ACCOUNTS A
			INNER JOIN ACC_TYPES AT ON AT.ACC_TYPE = A.ACC_TYPE WHERE A.ACC_ID = @depo_realize_acc_id
		IF @acc_type = 32  SET @result = CASE WHEN @is_lat = 1 THEN 'Deposit' ELSE 'ÓÀÀÍÀÁÒÏ' END
		IF @acc_type = 100 SET @result = CASE WHEN @is_lat = 1 THEN 'Current' ELSE 'ÌÉÌÃÉÍÀÒÄ' END
		IF @acc_type = 200 SET @result = CASE WHEN @is_lat = 1 THEN 'Plastic Card' ELSE 'ÓÀÁÀÒÀÈÄ' END
		RETURN(@result)
	END
	
	IF @param_name = 'DEPO_REALIZE_TYPE'
	BEGIN	
		IF @depo_realize_schema = 1
			SET @result = CASE WHEN @is_lat = 1 THEN 'End of period' ELSE 'ÅÀÃÉÓ ÁÏËÏÓ' END
		ELSE
		IF @depo_realize_schema = 2
			SET @result = CASE WHEN @is_lat = 1 THEN 'Never' ELSE 'ÀÒÀÓÏÃÄÓ' END
		ELSE
		IF @depo_realize_schema = 3
			SET @result = CASE WHEN @is_lat = 1 THEN 'equal amounts of the Deposit' ELSE 'ÀÍÀÁÒÉÓ ÈÀÍÀÁÀÒÉ ÈÀÍáÄÁÉ' END
		ELSE
		IF @depo_realize_schema = 4
			SET @result = CASE WHEN @is_lat = 1 THEN 'equal amounts together with benefit' ELSE 'ÓÀÒÂÄÁËÈÀÍ ÄÒÈÀÃ ÈÀÍÀÁÀÒÉ ÈÀÍáÄÁÉ' END
		ELSE
		IF @depo_realize_schema = 5
			SET @result = CASE WHEN @is_lat = 1 THEN 'equal amounts together with taxed benefit' ELSE 'ÃÀÁÄÂÒÉË ÓÀÒÂÄÁËÈÀÍ ÄÒÈÀÃ ÈÀÍÀÁÀÒÉ ÈÀÍáÄÁÉ' END

		RETURN(@result)
	END

	IF @param_name = 'INTEREST_REALIZE_ACCOUNT'
	BEGIN
		IF @interest_realize_acc_id IS NOT NULL 
			SET @result = CONVERT(varchar(1000), dbo.acc_get_account(@interest_realize_acc_id))
		ELSE
			SET @result = CONVERT(varchar(1000), dbo.acc_get_account(@depo_acc_id))

		RETURN(@result)
	END

	IF @param_name = 'INTEREST_REALIZE_ACCOUNT_TYPE'
	BEGIN
		IF (@interest_realize_acc_id IS NULL)
			SET @result = CASE WHEN @is_lat = 1 THEN 'Deposit' ELSE 'ÓÀÀÍÀÁÒÏ' END
		ELSE
		BEGIN
			SELECT @acc_type = AT.ACC_TYPE FROM ACCOUNTS A
				INNER JOIN ACC_TYPES AT ON AT.ACC_TYPE = A.ACC_TYPE WHERE A.ACC_ID = @interest_realize_acc_id
			IF @acc_type = 32  SET @result = CASE WHEN @is_lat = 1 THEN 'Deposit' ELSE 'ÓÀÀÍÀÁÒÏ' END
			IF @acc_type = 100 SET @result = CASE WHEN @is_lat = 1 THEN 'Current' ELSE 'ÌÉÌÃÉÍÀÒÄ' END
			IF @acc_type = 200 SET @result = CASE WHEN @is_lat = 1 THEN 'Plastic Card' ELSE 'ÓÀÁÀÒÀÈÄ' END
		END
		RETURN(@result)
	END
	
	IF @param_name = 'INTEREST_REALIZE_TYPE'
	BEGIN				
		IF @realize_type = 1
		BEGIN
			SET @result = CASE WHEN @is_lat = 1 THEN 'every ' ELSE 'ÚÏÅÄËÉ ' END + CONVERT(varchar(5), @realize_count)
			IF @realize_count_type = 1
				SET @result = @result + CASE WHEN @is_lat = 1 THEN ' day' ELSE ' ÃÙÉÓ ÛÄÌÃÄÂ' END
			ELSE
			IF @realize_count_type = 2
				SET @result = @result + CASE WHEN @is_lat = 1 THEN ' Month' ELSE ' ÈÅÉÓ ÛÄÌÃÄÂ' END
			ELSE
			IF @realize_count_type = 3
				SET @result = @result + CASE WHEN @is_lat = 1 THEN ' Month(30)' ELSE ' ÈÅÉÓ(30) ÛÄÌÃÄÂ' END
		END
		ELSE
		IF @realize_type = 2
		BEGIN
			IF @realize_count_type = 0
				SET @result = CASE WHEN @is_lat = 1 THEN 'at the end of the term' ELSE 'ÅÀÃÉÓ ÁÏËÏÓ' END
			ELSE
				SET @result = CONVERT(varchar(5), @realize_count) + CASE WHEN @is_lat = 1 THEN ' at the end of the month' ELSE ' ÈÅÉÓ ÁÏËÏÓ' END
		END
		ELSE
		IF @realize_type = 3
			SET @result = CASE WHEN @is_lat = 1 THEN 'at the time of accrual' ELSE 'ÃÀÒÉÝáÅÉÓ ÃÒÏÓ' END
		ELSE
		IF @realize_type = 4
			SET @result = CASE WHEN @is_lat = 1 THEN 'Never' ELSE 'ÀÒÀÓÏÃÄÓ' END

		RETURN(@result)
	END

	IF @param_name = 'ISO_DESCRIP'
	BEGIN
		SELECT @result = CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END FROM VAL_CODES
		WHERE ISO = @iso

		RETURN(@result)
	END

	IF @param_name = 'IS_SHAREABLE_TEXT'
	BEGIN
		IF @shareable = 1
	    BEGIN      
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'disposal by the Deposit Owners (including violation or lease) ' ELSE 'ÀÍÀÁÀÒÓ ÌÄÀÍÀÁÒÄÄÁÉ ÂÀÍÊÀÒÂÀÅÄÍ, ÌÀÈ ÛÏÒÉÓ ÀÒÙÅÄÅÄÍ ÀÍ ÀÂÉÒÀÅÄÁÄÍ ' END
			IF @shared_control = 1
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'only jointly' ELSE 'ÌáÏËÏÃ ÄÒÈÏÁËÉÅÀÃ' END
			ELSE
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'independently from each other' ELSE 'ÄÒÈÌÀÍÄÈÉÓÂÀÍ ÃÀÌÏÖÊÉÃÄÁËÀÃ' END
	    END
		ELSE 
			SET @result = '';

		RETURN(@result)
	END

	IF @param_name = 'ON_CLOSE_ACTION'
	BEGIN
		IF  @renewable <> 1
		BEGIN
			SELECT @acc_type = AT.ACC_TYPE FROM ACCOUNTS A
				INNER JOIN ACC_TYPES AT ON AT.ACC_TYPE = A.ACC_TYPE WHERE A.ACC_ID = @depo_realize_acc_id
			IF @acc_type = 100
				SET @result = CASE WHEN @is_lat = 1 THEN 'transfer of the existing residue to Current Account N-' ELSE 'ÀÒÓÄÁÖËÉ ÍÀÛÈÉÓ ÂÀÃÀÒÉÝáÅÀ ÌÉÌÃÉÍÀÒÄ ÀÍÂÀÒÉÛÆÄ N-' END + CONVERT(varchar(1000), dbo.acc_get_account(@depo_realize_acc_id))
			IF @acc_type = 200
				SET @result = CASE WHEN @is_lat = 1 THEN 'transfer of the existing residue to Plastic Card Account N-' ELSE 'ÀÒÓÄÁÖËÉ ÍÀÛÈÉÓ ÂÀÃÀÒÉÝáÅÀ ÓÀÁÀÒÀÈÄ ÀÍÂÀÒÉÛÆÄ N-' END + CONVERT(varchar(1000), dbo.acc_get_account(@depo_realize_acc_id))
		END
	    ELSE
			IF @renew_capitalized = 1
				SET @result = CASE WHEN @is_lat = 1 THEN 'Automatic extension together with benefit' ELSE 'ÀÅÔÏÌÀÔÖÒÉ ÐÒÏËÏÍÂÀÝÉÀ ÓÀÒÂÄÁÄËÈÀÍ ÄÒÈÀÃ' END
			ELSE
				SET @result = CASE WHEN @is_lat = 1 THEN 'Automatic extension together withOUT benefit' ELSE 'ÀÅÔÏÌÀÔÖÒÉ ÐÒÏËÏÍÂÀÝÉÀ ÃÀÒÉÝáÖËÉ ÓÀÒÂÄÁËÉÓ ÂÀÒÄÛÄ' END

		RETURN(@result)
	END

	IF @param_name = 'IS_PROLONGATION_TEXT'
	BEGIN
		IF @renewable = 1
			SET @result = CASE WHEN @is_lat = 1 THEN 
								'2.  In case of automatic extension of the Deposit term:' + CHAR(13) +
								'The Depositor’s failure to visit the Bank on the expiry date of the Deposit shall lead to automatic extension ' +
								'of the Deposit for the period provided for in Paragraph 2.3 of the Agreement. The Bank’s interest rate ' +
								'active as off the extension date shall be applied to the extended deposit, while all other Agreement ' +
								'conditions shall remain unchanged. During one month the Depositor has a right to withdraw the ' +
								'extended deposit without submitting a written application. No benefit shall be accrued for the ' +
								'above period. After one month, withdrawal of the deposit before its expiry date shall lead ' +
								'to administration of conditions provided for premature withdrawal of the deposit and the Bank ' +
								'shall charge the interest benefit valid as off the violation date. Upon expiry of the automatically ' +
								'extended period the residual amount sitting on the deposit account shall be transferred to the ' +
								'Depositor’s Current Account N ' + CONVERT(varchar(100), dbo.acc_get_account(@depo_realize_acc_id)) +  
								'The residual amount sitting on the Deposit Account shall be transferred to the same ' +
								'Account if any loans have been given under the deposit guarantee. If any loans have been given ' +
								'under the deposit guarantee, the Deposit shall not be subject to extension.'
							ELSE
								'2.  ÀÍÀÁÒÉÓ ÀÅÔÏÌÀÔÖÒÉ ÐÒÏËÏÍÂÀÝÉÉÓ ÛÄÌÈáÅÄÅÀÛÉ:' + CHAR(13) +
								'ÀÍÀÁÒÉÓ ÐÒÏËÏÍÂÀÝÉÀ ÌÏáÃÄÁÀ ÌÄÀÍÀÁÒÉÓ ÌÉÄÒ ÀÍÀÁÒÉÓ ÅÀÃÉÓ ÂÀÓÅËÉÓ ÃÙÄÓ ÁÀÍÊÛÉ ÂÀÌÏÖÝáÀÃÄÁËÏÁÉÓ ' +
								'ÛÄÌÈáÅÄÅÀÛÉ, áÄËÛÄÊÒÖËÄÁÉÓ 2.3 ÌÖáËÛÉ ÂÀÍÓÀÆÙÅÒÖËÉ ÅÀÃÉÈ. ÐÒÏËÏÍÂÉÒÄÁÖË ÀÍÀÁÀÒÆÄ ÉÌÏØÌÄÃÄÁÓ ' +
								'ÐÒÏËÏÍÂÀÝÉÉÓ ÃÙÄÓ ÁÀÍÊÉÓ ÔÀÒÉ×ÄÁÉÈ ÌÏØÌÄÃÉ ÓÀÐÒÏÝÄÍÔÏ ÂÀÍÀÊÅÄÈÉ. áÄËÛÄÊÒÖËÄÁÉÓ ÚÅÄËÀ ÓáÅÀ ' +
								'ÐÉÒÏÁÀ ÒÜÄÁÀ ÖÝÅËÄËÉ. ÌÄÀÍÀÁÒÄÓ ÄÒÈÉ ÈÅÉÓ ÂÀÍÌÀÅËÏÁÀÛÉ ÛÄÖÞËÉÀ ÂÀÉÔÀÍÏÓ ÐÒÏËÏÍÂÉÒÄÁÖËÉ ÀÍÀÁÀÒÉ ' +
								'ßÄÒÉËÏÁÉÈÉ ÂÀÍÝáÀÃÄÁÉÓ ÂÀÒÄÛÄ. ÀÙÍÉÛÍÖË ÐÄÒÉÃÆÄ ÀÍÀÁÀÒÓ ÓÀÄÒÂÄÁÄËÉ ÀÒ ÄÒÉÝáÄÁÀ. ÄÒÈÉ ÈÅÉÓ ÛÄÌÃÄÂ ' +
								'ÐÒÏËÏÍÂÉÒÄÁÖËÉ ÀÍÀÁÒÉÓ ÅÀÃÀÆÄ ÀÃÒÄ ÂÀÔÀÍÉÓ ÛÄÌÈáÅÄÅÀÛÉ ÌÏØÌÄÃÄÁÓ ÀÍÀÁÒÉÓ ÃÀÒÙÅÄÅÉÓÈÅÉÓ ' +
								'ÂÀÈÅÀËÉÓßÉÍÄÁÖËÉ ÐÉÒÏÁÄÁÉ ÃÀ ÀÍÀÁÀÒÓ ÃÀÄÒÉÝáÄÁÀ ÃÀÒÙÅÄÅÉÓ ÌÏÌÄÍÔÉÓÀÈÅÉÓ ÁÀÍÊÛÉ ÀÍÀÁÒÉÓ ÃÀÒÙÅÄÅÉÓ ' +
								'ÛÄÓÀÁÀÌÉÓÉ ÓÀÐÒÏÝÄÍÔÏ ÓÀÒÂÄÁÄËÉ. ÀÍÀÁÒÉÓ ÀÅÔÏÌÀÔÖÒÉ ÐÒÏËÏÍÂÀÝÉÉÓ ÅÀÃÉÓ ÂÀÓÅËÉÓ ÛÄÌÃÄÂ, ÓÀÀÍÀÁÒÏ ' +
								'ÀÍÂÀÒÉÛÆÄ ÀÒÓÄÁÖËÉ ÍÀÛÈÉ ÂÀÃÀÉÒÉÝáÄÁÀ ÌÄÀÍÀÁÒÉÓ ÌÉÌÃÉÍÀÒÄ ÀÍÂÀÒÉÛÆÄ N' + CONVERT(varchar(100), dbo.acc_get_account(@depo_realize_acc_id)) + '. ÀÌÀÅÄ ÀÍÂÀÒÉÛÆÄ ' +
								'ÂÀÃÀÉÒÉÝáÄÁÀ ÀÍÀÁÀÒÆÄ ÃÀÒÜÄÍÉËÉ ÍÀÛÈÉ ÀÍÀÁÒÉÓ ÖÆÒÖÍÅÄËÚÏ×ÉÈ  ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ÛÄÌÈáÅÄÅÀÛÉ. ÀÍÀÁÒÉÓ ' +
								'ÖÆÒÖÍÅÄËÚÏ×ÉÈ ÓÄÓáÉÓ ÂÀÝÄÌÉÓ ÛÄÌÈáÅÄÅÀÛÉ, ÀÍÀÁÀÒÉ ÐÒÏËÏÍÂÀÝÉÀÓ ÀÒ ÄØÅÄÌÃÄÁÀÒÄÁÀ.'
							END
		ELSE 
			SET @result = ''

		RETURN(@result)
	END

	IF @param_name = 'IS_PROLONGATION_TEXT_2'
	BEGIN
		SET @result = ''
		RETURN(@result)
	END

	IF @param_name = 'IS_PROLONGATION_TEXT_3'
	BEGIN
		SET @result = ''
		RETURN(@result)
	END

	IF @param_name = 'DEPOSITOR_DETAILS'
	BEGIN
		SET @result = ''
		SET @str0 = ''
		SET @str1 = ''
		SET @str2 = ''
		SET @str3 = ''
		
		SELECT @str0 = CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END, 
				@personal_id = C.PERSONAL_ID, @phone1 = C.PHONE1, 
				@attrib_value = CA.ATTRIB_VALUE
		FROM dbo.CLIENTS C
			INNER JOIN dbo.CLIENT_ATTRIBUTES CA ON CA.CLIENT_NO = C.CLIENT_NO
		WHERE CA.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END AND C.CLIENT_NO = @client_no
 
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@str0, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tel: ' ELSE 'ÔÄË: ' END + ISNULL(@phone1, '') + CHAR(13)

		IF @shareable = 1
		BEGIN
			SELECT @str3 = C.DESCRIP, @personal_id = C.PERSONAL_ID, @phone1 = C.PHONE1, @attrib_value = CA.ATTRIB_VALUE 
			FROM dbo.CLIENTS C
				INNER JOIN dbo.CLIENT_ATTRIBUTES CA ON CA.CLIENT_NO = C.CLIENT_NO
			WHERE CA.ATTRIB_CODE = '$ADDRESS_LEGAL' AND C.CLIENT_NO = @shared_control_client_no

			SET @result = @result + CHAR(13) + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@str3, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tel: ' ELSE 'ÔÄË: ' END + ISNULL(@phone1, '') + CHAR(13)
		END

		IF @child_deposit = 1
		BEGIN
			SELECT @str1 = C.DESCRIP, @personal_id = C.PERSONAL_ID, @phone1 = C.PHONE1, @attrib_value = CA.ATTRIB_VALUE 
			FROM CLIENTS C
				INNER JOIN CLIENT_ATTRIBUTES CA ON CA.CLIENT_NO = C.CLIENT_NO
			WHERE CA.ATTRIB_CODE = '$ADDRESS_LEGAL' AND C.CLIENT_NO = @child_control_client_no_1
			SET @result = @result + CHAR(13) + CHAR(13)

			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@str1, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
			SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tel: ' ELSE 'ÔÄË: ' END + ISNULL(@phone1, '') + CHAR(13)

			IF @child_control_client_no_2 IS NOT NULL
			BEGIN
				SELECT @str2 = C.DESCRIP, @personal_id = C.PERSONAL_ID, @phone1 = C.PHONE1, @attrib_value = CA.ATTRIB_VALUE 
				FROM CLIENTS C
					INNER JOIN CLIENT_ATTRIBUTES CA ON CA.CLIENT_NO = C.CLIENT_NO
				WHERE CA.ATTRIB_CODE = '$ADDRESS_LEGAL' AND C.CLIENT_NO = @child_control_client_no_2

				SET @result = @result + CHAR(13) + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@str2, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
				SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tel: ' ELSE 'ÔÄË: ' END + ISNULL(@phone1, '') + CHAR(13)
			END
		END
		
		IF @trust_deposit = 0
		BEGIN
			SET @result = @result + CHAR(13) + CHAR(13);
			SET @result = @result + '_______________________ /' + ISNULL(@str0, '') + '/' + CHAR(13) + CHAR(13);

			IF LTRIM(RTRIM(ISNULL(@str3, ''))) <> ''
				SET @result = @result + '_______________________ /' + @str3 + '/' + CHAR(13) + CHAR(13);

			IF LTRIM(RTRIM(ISNULL(@str1, ''))) <> ''
			BEGIN
				IF LTRIM(RTRIM(ISNULL(@str2, ''))) <> ''
					SET @result = @result + CASE WHEN @is_lat = 1 THEN '                    Representatives' ELSE '                    ßÀÒÌÏÌÀÃÂÄÍËÄÁÉ' END
				ELSE
					SET @result = @result + CASE WHEN @is_lat = 1 THEN '                    Representative'	ELSE '                    ßÀÒÌÏÌÀÃÂÄÍÄËÉ' END
				SET @result = @result + CHAR(13)
				SET @result = @result + CHAR(13)
				SET @result = @result + '_______________________ /' + @str1 + '/' + CHAR(13) + CHAR(13);
			END

			IF LTRIM(RTRIM(ISNULL(@str2, ''))) <> ''
				SET @result = @result + '_______________________ /' + @str2 + '/' + CHAR(13) + CHAR(13);
		END

		RETURN(@result)
	END

	IF @param_name = 'DEPOSITOR_REPRESENTATIVE_DETAILS'
	BEGIN

		SELECT @str0 = CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END, @passport = PASSPORT, @personal_id = PERSONAL_ID, @passport_issue_dt = PASSPORT_ISSUE_DT, @passport_reg_organ = PASSPORT_REG_ORGAN 
		FROM dbo.CLIENTS
		WHERE CLIENT_NO = @child_control_client_no_1
		
		SET @passport_issue_dt = convert(smalldatetime,floor(convert(real, @passport_issue_dt)))
		
		IF @is_lat = 1
			SET @result = @str0 + ' (ID N' + ISNULL(@passport, '') + ', Personal N' + ISNULL(@personal_id, '') + ', Place of issue ' + ISNULL(@passport_reg_organ, '') + ', Date of Issue ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'
		ELSE
			SET @result = @str0 + ' (Ð/Ì N' + ISNULL(@passport, '') + ', ÐÉÒÀÃÉ N' + ISNULL(@personal_id, '') + ', ÂÀÝ. ÀÃÂÉËÉ ' + ISNULL(@passport_reg_organ, '') + ', ÂÀÝ. ÈÀÒÉÙÉ ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'

		IF @child_control_client_no_2 IS NOT NULL
		BEGIN			
			SELECT @str0 = CASE WHEN @is_lat = 1 THEN DESCRIP_LAT ELSE DESCRIP END, @passport = PASSPORT, @personal_id = PERSONAL_ID, @passport_issue_dt = PASSPORT_ISSUE_DT, @passport_reg_organ = PASSPORT_REG_ORGAN 
			FROM dbo.CLIENTS
			WHERE CLIENT_NO = @child_control_client_no_2
			SET @passport_issue_dt = convert(smalldatetime,floor(convert(real, @passport_issue_dt)))
			SET @result = @result + CHAR(13)
			IF @is_lat = 1
				SET @result = @result + @str0 + ' (ID N' + ISNULL(@passport, '') + ', Personal N' + ISNULL(@personal_id, '') + ', Place of issue ' + ISNULL(@passport_reg_organ, '') + ', Date of Issue ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'
			ELSE
				SET @result = @result + @str0 + ' (Ð/Ì N' + ISNULL(@passport, '') + ', ÐÉÒÀÃÉ N' + ISNULL(@personal_id, '') + ', ÂÀÝ. ÀÃÂÉËÉ ' + ISNULL(@passport_reg_organ, '') + ', ÂÀÝ. ÈÀÒÉÙÉ ' + ISNULL(CONVERT(varchar(11), @passport_issue_dt), '') +')'
			END
		RETURN(@result)
	END

	IF @param_name = 'TRUST_CLIENT_DESCRIP'
	BEGIN		

		SELECT	@descr = CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END
		FROM dbo.CLIENTS C
		WHERE CLIENT_NO = @trust_client_no

		SET @result = @descr
		RETURN(@result)
	END

	IF @param_name = 'TRUST_EXTRA_INFO'
	BEGIN		

		SELECT @result=TRUST_EXTRA_INFO 
		FROM dbo.DEPO_DEPOSITS D
		WHERE D.DEPO_ID = @depo_id
		
		RETURN(@result)
	END

	IF @param_name = 'TRUST_CLIENT_DETAILS'
	BEGIN
		SET @result = ''
		SET @str0 = ''
		SET @str1 = ''
		SET @str2 = ''
		SET @str3 = ''
		
		SELECT @str0 = CASE WHEN @is_lat = 1 THEN C.DESCRIP_LAT ELSE C.DESCRIP END, 
				@personal_id = C.PERSONAL_ID, @phone1 = C.PHONE1, 
				@attrib_value = CA.ATTRIB_VALUE
		FROM dbo.CLIENTS C
			INNER JOIN dbo.CLIENT_ATTRIBUTES CA ON CA.CLIENT_NO = C.CLIENT_NO
		WHERE CA.ATTRIB_CODE = CASE WHEN @is_lat = 1 THEN '$ADDRESS_LAT' ELSE '$ADDRESS_LEGAL' END AND C.CLIENT_NO = @trust_client_no
 
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Name, Surname: ' ELSE 'ÓÀáÄËÉ, ÂÅÀÒÉ: ' END + ISNULL(@str0, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Personal ID: ' ELSE 'ÐÉÒÀÃÉ #: ' END + ISNULL(@personal_id, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Address: ' ELSE 'ÌÉÓÀÌÀÒÈÉ: ' END + ISNULL(@attrib_value, '') + CHAR(13)
		SET @result = @result + CASE WHEN @is_lat = 1 THEN 'Tel: ' ELSE 'ÔÄË: ' END + ISNULL(@phone1, '') + CHAR(13)

		SET @result = @result + CHAR(13) + CHAR(13);
		SET @result = @result + '_______________________ /' + ISNULL(@str0, '') + '/' + CHAR(13) + CHAR(13);

	END

	IF @param_name = 'CUSTPRM_1'
	BEGIN
		SET @result = 'TEST'
		RETURN(@result)
	END

		RETURN @result
END
GO
