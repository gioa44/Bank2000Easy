SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PLASTIC_CARDS_ADD_NEW_WITH_OLD_INFO_TO_SEND]
	@client_no int,
	@card_id varchar(19)

AS

SET NOCOUNT ON

DECLARE
	@bin int,
	@card_type int, 
	@card_name varchar(24),
	@card_expiry smalldatetime,
	@client_address varchar(60),
	@base_supp bit,
	@password varchar(20),
	@contract varchar(15),
	@enrolled smalldatetime,
	@dept_no int,
	@condition_set char(3),
	@card_expiry_year tinyint,
	@client_category char(3),
	@card_category char(3),
	@card_chip int,
	@prod_code varchar(10),
	@authorize_code tinyint

	SELECT	@bin = BIN, @card_type = CARD_TYPE, @card_name = CARD_NAME, @client_address = CLIENT_ADDRESS,
			@base_supp = BASE_SUPP, @password = PASSWORD, @contract = CONTRACT, @enrolled = ENROLLED,
			@dept_no = DEPT_NO, @condition_set = CONDITION_SET, @client_category = CLIENT_CATEGORY,
			@card_chip = CARD_CHIP, @prod_code = PROD_CODE, @authorize_code = AUTHORIZE_CODE
	FROM	dbo.PLASTIC_CARDS
	WHERE	CARD_ID = @card_id AND CLIENT_NO = @client_no

	SELECT	@card_expiry_year = CARD_EXPIRY_YEAR 
	FROM	CCARD_TYPES
	WHERE	REC_ID = @card_type

	SET @card_expiry = DATEADD(yy, 1, convert(smalldatetime,floor(convert(real,getdate()))))

	INSERT INTO dbo.PLASTIC_CARDS_FOR_SEND
			(CLIENT_NO,BIN,CARD_TYPE,CARD_NAME,CARD_EXPIRY,CLIENT_ADDRESS,BASE_SUPP,PASSWORD
			,CONTRACT,ENROLLED,DEPT_NO,CONDITION_SET,CARD_ID_OLD,CLIENT_CATEGORY,IS_NEW_CLIENT,CARD_CHIP,PROD_CODE,AUTHORIZE_CODE)
     VALUES(@client_no,@bin,@card_type,@card_name,@card_expiry,@client_address,@base_supp,@password,@contract
			,@enrolled,@dept_no,@condition_set,@card_id,@client_category,0,@card_chip,@prod_code,@authorize_code)

RETURN 0
GO
