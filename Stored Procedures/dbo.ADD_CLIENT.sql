SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ADD_CLIENT] (
	@client_no int OUTPUT,
	@user_id int = NULL,		-- ÅÉÍ ÀÌÀÔÄÁÓ ÀÍÂÀÒÉÛÓ
	@dept_no int = NULL,		-- ×ÉËÉÀËÉ

	@client_type tinyint = 1,
	@client_subtype tinyint = null,
	@client_subtype2 int = null,
	@rec_state tinyint = 1,
	@completed bit = 1,
	@responsible_user_id int = null,
	@client_type_bank tinyint = 1,
	@descrip varchar(100),
	@descrip_lat varchar(100) = null,
	@client_reg_date smalldatetime,
	@is_resident bit = 1,
	@is_insider bit = 0,
	@country char(2) = 'GE',
	@first_name varchar(50),
	@last_name varchar(50),
	@first_name_lat varchar(50) = null,
	@last_name_lat varchar(50) = null,
	@fathers_name varchar(50) = null,
	@fathers_name_lat varchar(50) = null,
	@male_female bit = null,
	@tax_insp_city varchar(20) = null,
	@tax_insp_code varchar(11) = null,
	@passport_type_id tinyint = null,
	@passport_country char(2) = null,
	@passport_issue_dt smalldatetime = null,
	@passport_end_date smalldatetime = null,
	@passport varchar(50) = null,
	@passport_reg_organ varchar(50) = null,
	@personal_id varchar(20) = null,
	@passport_needed bit = null,
	@phone_pin varchar(10) = null,
	@comment varchar(200) = null,
	@rate_politics_id int = null,
	@rate_diff_type bit = 0,
	@rate_tariff_always_in_gel bit = 0,
	@city varchar(20) = null,
	@phone1 varchar(62) = null,
	@phone2 varchar(12) = null,
	@birth_date smalldatetime = null,
	@birth_place varchar(100) = null,
	@marital_status tinyint = null,
	@org_type varchar(50) = null,
	@reg_num varchar(30) = null,
	@reg_date smalldatetime = null,
	@reg_organ varchar(50) = null,
	@segment tinyint = null,
	@city_lat varchar(20) = null,
	@is_employee bit = 0,
	@is_in_black_list bit = 0,
	@is_control bit = 0,
	@loan_limit_amount money = null,
	@loan_limit_iso TISO = null,
	@is_authorized bit = 0
) 
AS

SET NOCOUNT ON;

SET @descrip = ISNULL(@descrip, '')
SET @descrip = LTRIM(RTRIM(@descrip))

IF ISNULL(@descrip_lat, '') = ''
	SET @descrip_lat = @descrip

IF @client_reg_date IS NULL
	SET @client_reg_date = convert(smalldatetime,floor(convert(real,getdate())))

IF @responsible_user_id IS NULL
	SET @responsible_user_id = @user_id

DECLARE @branch_id int
SET @branch_id = dbo.dept_branch_id (@dept_no)

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

INSERT INTO dbo.CLIENTS (
	BRANCH_ID
   ,DEPT_NO
   ,CLIENT_TYPE
   ,CLIENT_SUBTYPE
   ,REC_STATE
   ,COMPLETED
   ,RESPONSIBLE_USER_ID
   ,CLIENT_TYPE_BANK
   ,DESCRIP
   ,DESCRIP_LAT
   ,CLIENT_REG_DATE
   ,IS_RESIDENT
   ,IS_INSIDER
   ,COUNTRY
   ,FIRST_NAME
   ,LAST_NAME
   ,FIRST_NAME_LAT
   ,LAST_NAME_LAT
   ,FATHERS_NAME
   ,FATHERS_NAME_LAT
   ,MALE_FEMALE
   ,TAX_INSP_CITY
   ,TAX_INSP_CODE
   ,PASSPORT_TYPE_ID
   ,PASSPORT_COUNTRY
   ,PASSPORT_ISSUE_DT
   ,PASSPORT_END_DATE
   ,PASSPORT
   ,PASSPORT_REG_ORGAN
   ,PERSONAL_ID
   ,PASSPORT_NEEDED
   ,PHONE_PIN
   ,COMMENT
   ,RATE_POLITICS_ID
   ,RATE_DIFF_TYPE
   ,RATE_TARIFF_ALWAYS_IN_GEL
   ,CITY
   ,PHONE1
   ,PHONE2
   ,BIRTH_DATE
   ,BIRTH_PLACE
   ,MARITAL_STATUS
   ,ORG_TYPE
   ,REG_NUM
   ,REG_DATE
   ,REG_ORGAN
   ,SEGMENT
   ,CITY_LAT
   ,IS_EMPLOYEE
   ,IS_IN_BLACK_LIST
   ,IS_CONTROL
   ,LOAN_LIMIT_AMOUNT
   ,LOAN_LIMIT_ISO
   ,CLIENT_SUBTYPE2
   ,IS_AUTHORIZED
)
VALUES 
(
	@branch_id,
	@dept_no,
	@client_type,
	@client_subtype,
	@rec_state,
	@completed,
	@responsible_user_id,
	@client_type_bank,
	@descrip,
	@descrip_lat,
	@client_reg_date,
	@is_resident,
	@is_insider,
	@country,
	@first_name,
	@last_name,
	@first_name_lat,
	@last_name_lat,
	@fathers_name,
	@fathers_name_lat,
	@male_female,
	@tax_insp_city,
	@tax_insp_code,
	@passport_type_id,
	@passport_country,
	@passport_issue_dt,
	@passport_end_date,
	@passport,
	@passport_reg_organ,
	@personal_id,
	@passport_needed,
	@phone_pin,
	@comment,
	@rate_politics_id,
	@rate_diff_type,
	@rate_tariff_always_in_gel,
	@city,
	@phone1,
	@phone2,
	@birth_date,
	@birth_place,
	@marital_status,
	@org_type,
	@reg_num,
	@reg_date,
	@reg_organ,
	@segment,
	@city_lat,
	@is_employee,
	@is_in_black_list,
	@is_control,
	@loan_limit_amount,
	@loan_limit_iso,
	@client_subtype2,
	@is_authorized
)
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

SET @client_no = SCOPE_IDENTITY()

INSERT INTO dbo.CLI_CHANGES (CLIENT_NO, [USER_ID], DESCRIP)
VALUES (@client_no, @user_id, 'ÊËÉÄÍÔÉÓ ÃÀÌÀÔÄÁÀ')
IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 2 END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN

RETURN @@ERROR
GO
