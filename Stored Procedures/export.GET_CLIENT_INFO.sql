SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [export].[GET_CLIENT_INFO]
	@client_id int,
	@client_type tinyint = NULL
AS
DECLARE
	@client_subtype int

	IF @client_type IS NULL OR @client_type = -1
		SET @client_type = export.get_client_type3(@client_id)
		
	IF @client_type = 1
	BEGIN
		SELECT 
			u.USER_FULL_NAME AS RESPONSIBLE_OFFICER,
			export.get_bank_un_number() AS BANK_UN_NUMBER,
			cl.PERSONAL_ID,
			cl.LAST_NAME,
			cl.FIRST_NAME,
			cl.MALE_FEMALE,
			atr.ATTRIB_VALUE AS [ADDRESS],
			NULL AS ZIP_CODE,
			cl.COUNTRY,
			cl.PHONE1 AS PHONE,
			NULL AS FAX,
			cl.PHONE2 AS MOBILE,
			atr2.ATTRIB_VALUE AS EMAIL
		FROM dbo.CLIENTS cl
			LEFT JOIN dbo.USERS u ON u.[USER_ID] = cl.RESPONSIBLE_USER_ID
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr ON cl.CLIENT_NO = atr.CLIENT_NO AND atr.ATTRIB_CODE = '$ADDRESS_LEGAL'
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr2 ON cl.CLIENT_NO = atr2.CLIENT_NO AND atr2.ATTRIB_CODE = '$EMAIL'
		WHERE cl.CLIENT_NO = @client_id
	END
	ELSE
	IF @client_type = 2
	BEGIN
		SELECT 
			u.USER_FULL_NAME AS RESPONSIBLE_OFFICER,
			export.get_bank_un_number() AS BANK_UN_NUMBER,
			cl.PERSONAL_ID,
			cl.LAST_NAME,
			cl.FIRST_NAME,
			cl.MALE_FEMALE,
			cl.DESCRIP AS TRADE_NAME,
			6 AS LEGAL_FORM, -- ÂÅÉÍÃÀ ×ÖÍØÝÉÀ ÒÏÌÄËÉÝ ÀÌÀÓ ÃÀÀÁÒÖÍÄÁÓ
			cl.REG_NUM AS REG_NO,
			cl.REG_ORGAN AS PLACE_OF_REG,
			cl.REG_DATE AS DATE_ESTABLISHED,
			1 AS BUSINESS_STATUS,
			NULL AS NACE_CODE,
			cl.TAX_INSP_CODE AS TAX_NUMBER,
			NULL AS UNIQUE_NO,
			atr.ATTRIB_VALUE AS [ADDRESS],
			NULL AS ZIP_CODE,
			cl.COUNTRY,
			cl.PHONE1 AS PHONE,
			NULL AS FAX,
			cl.PHONE2 AS MOBILE,
			atr2.ATTRIB_VALUE AS EMAIL
		FROM dbo.CLIENTS cl
			LEFT JOIN dbo.USERS u ON u.[USER_ID] = cl.RESPONSIBLE_USER_ID
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr ON cl.CLIENT_NO = atr.CLIENT_NO AND atr.ATTRIB_CODE = '$ADDRESS_LEGAL'
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr2 ON cl.CLIENT_NO = atr2.CLIENT_NO AND atr2.ATTRIB_CODE = '$EMAIL'
		WHERE cl.CLIENT_NO = @client_id	END
	ELSE
	IF @client_type = 4
	BEGIN
		SELECT 
			u.USER_FULL_NAME AS RESPONSIBLE_OFFICER,
			export.get_bank_un_number() AS BANK_UN_NUMBER,
			cl.DESCRIP AS TRADE_NAME,
			23 AS LEGAL_FORM, -- ÂÅÉÍÃÀ ×ÖÍØÝÉÀ ÒÏÌÄËÉÝ ÀÌÀÓ ÃÀÀÁÒÖÍÄÁÓ
			cl.REG_NUM AS REG_NO,
			cl.REG_ORGAN AS PLACE_OF_REG,
			cl.REG_DATE AS DATE_ESTABLISHED,
			cl.COUNTRY AS REG_COUNTRY,
			NULL AS NACE_CODE,
			10 AS BUSINESS_STATUS,
			cl.TAX_INSP_CODE AS TAX_NUMBER,
			NULL AS UNIQUE_NO,
			atr.ATTRIB_VALUE AS [ADDRESS],
			NULL AS ZIP_CODE,
			NULL AS REGION,
			cl.COUNTRY,
			cl.PHONE1 AS PHONE,
			NULL AS FAX,
			cl.PHONE2 AS MOBILE,
			atr2.ATTRIB_VALUE AS EMAIL
		FROM dbo.CLIENTS cl
			LEFT JOIN dbo.USERS u ON u.[USER_ID] = cl.RESPONSIBLE_USER_ID
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr ON cl.CLIENT_NO = atr.CLIENT_NO AND atr.ATTRIB_CODE = '$ADDRESS_LEGAL'
			LEFT JOIN dbo.CLIENT_ATTRIBUTES atr2 ON cl.CLIENT_NO = atr2.CLIENT_NO AND atr2.ATTRIB_CODE = '$EMAIL'
		WHERE cl.CLIENT_NO = @client_id
	END
GO
