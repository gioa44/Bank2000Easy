SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[swift_message_builder]
	@doc_rec_id int,
	@doc_date smalldatetime,
	@swift_msg varchar(4000) OUTPUT
AS

SET NOCOUNT ON

DECLARE
	@MsgBegin char(1),
	@MsgEnd char(1),
	@Cr char(1),
	@Lf char(1),
	@CrLf char(2),
	@MsgType char(3),
	@oInputLT varchar(37)

SET @MsgBegin = CHAR(0x1)
SET @MsgEnd = CHAR(0x3)
SET @Cr = CHAR(0xD)
SET @Lf = CHAR(0xA)
SET @CrLf = @Cr + @Lf
SET @MsgType = '103'


DECLARE
	@r int, 
	@check bit

DECLARE
	@ref_num					varchar(32),
	@amount						money,
	@iso						char(3),
	@swift_iso					char(3),
	@sender_bank_code			varchar(37),
	@sender_bank_name			varchar(100),
	@sender_acc					varchar(37),
	@sender_acc_name			varchar(100),
	@sender_address_lat			varchar(105),
	@receiver_address_lat		varchar(105),
	@receiver_bank_code			varchar(37),
	@receiver_bank_name			varchar(100),
	@receiver_acc				varchar(37),
	@receiver_acc_name			varchar(100),
	@correspondent_bank_id		int,
	
	@receiver_institution_code	varchar(37),
	@cor_account				varchar(35),
	@cor_account_iso			char(3),
	



	@intermed_bank_code			varchar(37),
	@intermed_bank_name			varchar(100),
	@intermed_bank_code2		varchar(37),
	@intermed_bank_name2		varchar(100),


	@extra_info					varchar(255),
	@extra_info_descrip			bit,

	@det_of_payment				varchar(150),
	@det_of_charg				char(3)
SELECT
	@ref_num					= REF_NUM,
	@doc_date					= CASE WHEN @doc_date IS NULL THEN DOC_DATE ELSE @doc_date END,
	@amount						= AMOUNT,
	@iso						= ISO,
	@sender_bank_code			= UPPER(SENDER_BANK_CODE),
	@sender_bank_name			= UPPER(SENDER_BANK_NAME),
	@sender_acc					= SENDER_ACC,
	@sender_acc_name			= UPPER(SENDER_ACC_NAME),
	@sender_address_lat			= UPPER(LTRIM(RTRIM(SENDER_ADDRESS_LAT))),
	@receiver_bank_code			= UPPER(RECEIVER_BANK_CODE),
	@receiver_bank_name			= UPPER(RECEIVER_BANK_NAME),
	@receiver_acc				= RECEIVER_ACC,
	@receiver_acc_name			= UPPER(RECEIVER_ACC_NAME),
	@receiver_address_lat		= UPPER(LTRIM(RTRIM(RECEIVER_ADDRESS_LAT))),
	@correspondent_bank_id		= CORRESPONDENT_BANK_ID,
	@intermed_bank_code			= UPPER(INTERMED_BANK_CODE),
	@intermed_bank_name			= UPPER(INTERMED_BANK_NAME),
	@intermed_bank_code2		= UPPER(INTERMED_BANK_CODE2),
	@intermed_bank_name2		= UPPER(INTERMED_BANK_NAME2),

	@extra_info					= UPPER(EXTRA_INFO),
	@extra_info_descrip			= EXTRA_INFO_DESCRIP,

	@det_of_payment				= UPPER(DESCRIP),
	@det_of_charg				= UPPER(DET_OF_CHARG)
FROM impexp.DOCS_OUT_SWIFT (NOLOCK)
WHERE DOC_REC_ID = @doc_rec_id

SELECT @receiver_institution_code = BIC, @cor_account = LORO_ACCOUNT, @cor_account_iso = ISO
FROM dbo.CORRESPONDENT_BANKS (NOLOCK)
WHERE REC_ID = @correspondent_bank_id

DECLARE
	@tag_20 varchar(20),
	@tag_23B varchar(4),
	@tag_32A varchar(24),
	@tag_33B varchar(18),

	@tag_50x_opt char(1),
	@tag_50x_AccountNumber varchar(37),
	@tag_50x_NameAndAddress_1 varchar(35),
	@tag_50x_NameAndAddress_2 varchar(35),
	@tag_50x_NameAndAddress_3 varchar(35),
	@tag_50x_NameAndAddress_4 varchar(35),
	
	@tag_52x_opt char(1),
	@tag_52x_AccountNumber varchar(37),

	@tag_53x_opt char(1),
	@tag_53x_AccountNumber varchar(37),
	@tag_53x_CorAccountAndIso varchar(35),
	@tag_53x_NameAndAddress_1 varchar(35),
	@tag_53x_NameAndAddress_2 varchar(35),
	@tag_53x_NameAndAddress_3 varchar(35),
	@tag_53x_NameAndAddress_4 varchar(35),


	@tag_56x_opt char(1),
	@tag_56x_AccountNumber varchar(37),
	@tag_56x_NameAndAddress_1 varchar(35),
	@tag_56x_NameAndAddress_2 varchar(35),
	@tag_56x_NameAndAddress_3 varchar(35),
	@tag_56x_NameAndAddress_4 varchar(35),

	@tag_57x_opt char(1),
	@tag_57x_AccountNumber varchar(37),
	@tag_57x_NameAndAddress_1 varchar(35),
	@tag_57x_NameAndAddress_2 varchar(35),
	@tag_57x_NameAndAddress_3 varchar(35),
	@tag_57x_NameAndAddress_4 varchar(35),

	@tag_59x_AccountNumber varchar(37),
	@tag_59x_NameAndAddress_1 varchar(35),
	@tag_59x_NameAndAddress_2 varchar(35),
	@tag_59x_NameAndAddress_3 varchar(35),
	@tag_59x_NameAndAddress_4 varchar(35),

	@tag_70_Str35_1 varchar(35),
	@tag_70_Str35_2 varchar(35),
	@tag_70_Str35_3 varchar(35),
	@tag_70_Str35_4 varchar(35),
	
	@tag_71A char(3),

	@tag_72_Str35_1 varchar(35),
	@tag_72_Str35_2 varchar(35),
	@tag_72_Str35_3 varchar(35),
	@tag_72_Str35_4 varchar(35),
	@tag_72_Str35_5 varchar(35),
	@tag_72_Str35_6 varchar(35)

DECLARE
	@stub_str varchar(35)

SET @tag_20 = @ref_num
SET @tag_23B = 'CRED'
SET @swift_iso = 
	CASE
		WHEN @iso = 'RUR' THEN 'RUB'
		WHEN @iso = 'AVD' THEN 'AUD'
		ELSE @iso
	END 

SET @tag_32A = SUBSTRING(convert(char(4), DATEPART(yy, @doc_date)), 3, 2) + REPLICATE('0', 2 - LEN(convert(varchar(2), DATEPART(mm, @doc_date)))) + convert(varchar(2), DATEPART(mm, @doc_date)) + REPLICATE('0', 2 - LEN(convert(varchar(2), DATEPART(dd, @doc_date)))) + convert(varchar(2), DATEPART(dd, @doc_date))
SET @tag_32A = @tag_32A + @swift_iso
IF convert(int, @amount) = @amount
	SET @tag_32A = @tag_32A + convert(varchar(15), convert(int, @amount)) + ',' -- ეს პირობა არ ჩაწერს მეასედ თანხას თუ ის 00-ია
ELSE 
	SET @tag_32A = @tag_32A + REPLACE(convert(varchar(15), @amount), '.', ',')
 
SET @tag_33B = @swift_iso
IF convert(int, @amount) = @amount
	SET @tag_33B = @tag_33B + convert(varchar(15), convert(int, @amount)) + ',' -- ეს პირობა არ ჩაწერს მეასედ თანხას თუ ის 00-ია
ELSE
	SET @tag_33B = @tag_33B + REPLACE(convert(varchar(15), @amount), '.', ',')

SET @tag_50x_opt = 'K'
SET @tag_50x_AccountNumber = @sender_acc
/* -- ამ მოდელში ანგარიშის დასახელება და მისამართი შეიძლება იყოს ერთიდა იგივიე სტრიქონზე (მთლიანად ან ნაწილობრივ) -- */
/*DECLARE
	@sender_name_and_address varchar(140)
SET @sender_name_and_address = ISNULL(@sender_acc_name, '') 
IF ISNULL(@sender_name_and_address, '') <> '' AND ISNULL(@sender_address_lat, '') <> ''
	SET @sender_name_and_address = @sender_name_and_address + @Cr
IF ISNULL(@sender_address_lat, '') <> ''
	SET @sender_name_and_address = @sender_name_and_address + SUBSTRING(@sender_address_lat, 1, 140 - LEN(@sender_name_and_address))

EXEC impexp.swift_break_string_str35_4
	@str = @sender_name_and_address, -- @sender_acc_name + @sender_address_lat
	@sw_str_35_1 = @tag_50x_NameAndAddress_1 OUTPUT,
	@sw_str_35_2 = @tag_50x_NameAndAddress_2 OUTPUT,
	@sw_str_35_3 = @tag_50x_NameAndAddress_3 OUTPUT,
	@sw_str_35_4 = @tag_50x_NameAndAddress_4 OUTPUT*/
/* -- END OF ამ მოდელში ანგარიშის დასახელება და მისამართი შეიძლება იყოს ერთიდა იგივიე სტრიქონზე (მთლიანად ან ნაწილობრივ) -- */

/* -- ამ მოდელში ანგარიშის დასახელება და მისამართი აუცილებლად იქნება სხვადასხვა სტრიქონში -- */
EXEC impexp.swift_break_string_str35_4
	@str = @sender_acc_name,
	@sw_str_35_1 = @tag_50x_NameAndAddress_1 OUTPUT,
	@sw_str_35_2 = @tag_50x_NameAndAddress_2 OUTPUT,
	@sw_str_35_3 = @tag_50x_NameAndAddress_3 OUTPUT,
	@sw_str_35_4 = @tag_50x_NameAndAddress_4 OUTPUT

IF ISNULL(@tag_50x_NameAndAddress_1, '') = ''
	EXEC impexp.swift_break_string_str35_4
		@str = @sender_address_lat,
		@sw_str_35_1 = @tag_50x_NameAndAddress_1 OUTPUT,
		@sw_str_35_2 = @tag_50x_NameAndAddress_2 OUTPUT,
		@sw_str_35_3 = @tag_50x_NameAndAddress_3 OUTPUT,
		@sw_str_35_4 = @tag_50x_NameAndAddress_4 OUTPUT
ELSE
IF ISNULL(@tag_50x_NameAndAddress_2, '') = ''
	EXEC impexp.swift_break_string_str35_4
		@str = @sender_address_lat,
		@sw_str_35_1 = @tag_50x_NameAndAddress_2 OUTPUT,
		@sw_str_35_2 = @tag_50x_NameAndAddress_3 OUTPUT,
		@sw_str_35_3 = @tag_50x_NameAndAddress_4 OUTPUT,
		@sw_str_35_4 = @stub_str OUTPUT
ELSE
IF ISNULL(@tag_50x_NameAndAddress_3, '') = ''
	EXEC impexp.swift_break_string_str35_4
		@str = @sender_address_lat,
		@sw_str_35_1 = @tag_50x_NameAndAddress_3 OUTPUT,
		@sw_str_35_2 = @tag_50x_NameAndAddress_4 OUTPUT,
		@sw_str_35_3 = @stub_str OUTPUT,
		@sw_str_35_4 = @stub_str OUTPUT
ELSE
IF ISNULL(@tag_50x_NameAndAddress_4, '') = ''
	EXEC impexp.swift_break_string_str35_4
		@str = @sender_address_lat,
		@sw_str_35_1 = @tag_50x_NameAndAddress_4 OUTPUT,
		@sw_str_35_2 = @stub_str OUTPUT,
		@sw_str_35_3 = @stub_str OUTPUT,
		@sw_str_35_4 = @stub_str OUTPUT
/* -- ამ მოდელში ანგარიშის დასახელება და მისამართი აუცილებლად იქნება სხვადასხვა სტრიქონში -- */

SET @tag_52x_opt = 'A'
--SET @tag_52x_AccountNumber = SUBSTRING(@sender_bank_code, 1, 8) რესპუბლიკა
SET @tag_52x_AccountNumber = @sender_bank_code

/* –– ეს არის BANK Republic მოდელი */

--IF @iso <> @cor_account_iso AND ISNULL(@cor_account, '') <> ''
--BEGIN
--	SET @tag_53x_opt = 'B'
--	SET @tag_53x_CorAccountAndIso = '/' + @cor_account
--END

/* –– END OF ეს არის BANK Republic მოდელი */

/**/
IF @iso <> @cor_account_iso AND ISNULL(@cor_account, '') <> ''
BEGIN
	SET @tag_53x_opt = 'A'
	SET @tag_53x_CorAccountAndIso = '/' + @cor_account + @cor_account_iso
	SET @tag_53x_NameAndAddress_1 = SUBSTRING(@sender_bank_code, 1, 8) + 'XXX'
END
/**/ -- ეს არის TBC მოდელი

IF @intermed_bank_code = '.'
BEGIN
	SET @tag_56x_opt = 'D'
	EXEC impexp.swift_break_string_str35_4
		@str = @intermed_bank_name,
		@sw_str_35_1 = @tag_56x_NameAndAddress_1 OUTPUT,
		@sw_str_35_2 = @tag_56x_NameAndAddress_2 OUTPUT,
		@sw_str_35_3 = @tag_56x_NameAndAddress_3 OUTPUT,
		@sw_str_35_4 = @tag_56x_NameAndAddress_4 OUTPUT
END
ELSE
IF CHARINDEX('/', @intermed_bank_code) <> 0
BEGIN
	SET @tag_56x_opt = 'D'
	SET @tag_56x_AccountNumber = @intermed_bank_code
	EXEC impexp.swift_break_string_str35_4
		@str = @intermed_bank_name,
		@sw_str_35_1 = @tag_56x_NameAndAddress_1 OUTPUT,
		@sw_str_35_2 = @tag_56x_NameAndAddress_2 OUTPUT,
		@sw_str_35_3 = @tag_56x_NameAndAddress_3 OUTPUT,
		@sw_str_35_4 = @tag_56x_NameAndAddress_4 OUTPUT
END
ELSE
BEGIN
	SET @tag_56x_opt = 'A'
	SET @tag_56x_AccountNumber = @intermed_bank_code
END

IF @receiver_bank_code = '.'
BEGIN
	SET @tag_57x_opt = 'D'
	EXEC impexp.swift_break_string_str35_4
		@str = @receiver_bank_name,
		@sw_str_35_1 = @tag_57x_NameAndAddress_1 OUTPUT,
		@sw_str_35_2 = @tag_57x_NameAndAddress_2 OUTPUT,
		@sw_str_35_3 = @tag_57x_NameAndAddress_3 OUTPUT,
		@sw_str_35_4 = @tag_57x_NameAndAddress_4 OUTPUT
END
ELSE
IF CHARINDEX('/', @receiver_bank_code) <> 0
BEGIN
	SET @tag_57x_opt = 'D'
	SET @tag_57x_AccountNumber = @receiver_bank_code
	EXEC impexp.swift_break_string_str35_4
		@str = @receiver_bank_name,
		@sw_str_35_1 = @tag_57x_NameAndAddress_1 OUTPUT,
		@sw_str_35_2 = @tag_57x_NameAndAddress_2 OUTPUT,
		@sw_str_35_3 = @tag_57x_NameAndAddress_3 OUTPUT,
		@sw_str_35_4 = @tag_57x_NameAndAddress_4 OUTPUT
END
ELSE
BEGIN
	SET @tag_57x_opt = 'A'
	SET @tag_57x_AccountNumber = @receiver_bank_code
END

SET @oInputLT =	CASE 
		WHEN ISNULL(@receiver_institution_code, '')	<> '' THEN SUBSTRING(@receiver_institution_code, 1, 8) + 'XXXX'
		WHEN ISNULL(@tag_56x_AccountNumber, '') <> '' THEN SUBSTRING(@tag_56x_AccountNumber, 1, 8) + 'XXXX'
		WHEN ISNULL(@tag_57x_AccountNumber, '') <> '' THEN SUBSTRING(@tag_57x_AccountNumber, 1, 8) + 'XXXX'
		ELSE NULL 
	END

SET @tag_59x_AccountNumber = @receiver_acc
SET @receiver_acc_name = RTRIM(ISNULL(@receiver_acc_name,'') + ' ' + ISNULL(@receiver_address_lat, ''))
EXEC impexp.swift_break_string_str35_4
	@str = @receiver_acc_name,
	@sw_str_35_1 = @tag_59x_NameAndAddress_1 OUTPUT,
	@sw_str_35_2 = @tag_59x_NameAndAddress_2 OUTPUT,
	@sw_str_35_3 = @tag_59x_NameAndAddress_3 OUTPUT,
	@sw_str_35_4 = @tag_59x_NameAndAddress_4 OUTPUT

EXEC impexp.swift_break_string_str35_4
	@str = @det_of_payment,
	@sw_str_35_1 = @tag_70_Str35_1 OUTPUT,
	@sw_str_35_2 = @tag_70_Str35_2 OUTPUT,
	@sw_str_35_3 = @tag_70_Str35_3 OUTPUT,
	@sw_str_35_4 = @tag_70_Str35_4 OUTPUT

SET @tag_71A = @det_of_charg


/* -- გადატანილია impexp.swift_message_builder_on_user_tag72–ში, შეასწორეთ(მარილი) გემოვნებით
IF @extra_info_descrip = 0
	EXEC impexp.swift_break_string_str35_6
		@str = @extra_info,
		@sw_str_35_1 = @tag_72_Str35_1 OUTPUT,
		@sw_str_35_2 = @tag_72_Str35_2 OUTPUT,
		@sw_str_35_3 = @tag_72_Str35_3 OUTPUT,
		@sw_str_35_4 = @tag_72_Str35_4 OUTPUT,
		@sw_str_35_5 = @tag_72_Str35_5 OUTPUT,
		@sw_str_35_6 = @tag_72_Str35_6 OUTPUT
ELSE
BEGIN
	--SET @tag_72_Str35_1 = '/ACC/RFB/CONTINUED' /* –– ეს არის TBC მოდელი */
	SET @tag_72_Str35_1 = '/BNF/CONTINUED' /* –– ეს არის BANK Republic მოდელი */
	EXEC impexp.swift_break_string_str35_6
		@str = @extra_info,
		@sw_str_35_1 = @tag_72_Str35_2 OUTPUT,
		@sw_str_35_2 = @tag_72_Str35_3 OUTPUT,
		@sw_str_35_3 = @tag_72_Str35_4 OUTPUT,
		@sw_str_35_4 = @tag_72_Str35_5 OUTPUT,
		@sw_str_35_5 = @tag_72_Str35_6 OUTPUT,
		@sw_str_35_6 = @stub_str OUTPUT
END*/

DECLARE
	@tag_value varchar(255)

DELETE FROM impexp.SWIFT_MESSAGE_HELPER WHERE DOC_REC_ID = @doc_rec_id

INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@doc_rec_id, '{1', NULL, ':F01' + @tag_52x_AccountNumber + 'AXXX' + '0000000000' + '}')
INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@doc_rec_id, '{2', NULL, ':I' + @MsgType + @oInputLT + 'N' + '}')
INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@doc_rec_id, '{4', NULL, ':' + @CrLf)

IF ISNULL(@tag_20, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '20', NULL, @tag_20 + @CrLf)
IF ISNULL(@tag_23B, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '23', 'B', @tag_23B + @CrLf)
IF ISNULL(@tag_32A, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '32', 'A', @tag_32A + @CrLf)
IF ISNULL(@tag_33B, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '33', 'B', @tag_33B + @CrLf)


SET @tag_value = ''
IF ISNULL(@tag_50x_AccountNumber, '') <> ''
	SET @tag_value = '/' + @tag_50x_AccountNumber + @CrLf	
IF ISNULL(@tag_50x_NameAndAddress_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_50x_NameAndAddress_1 + @CrLf

	IF ISNULL(@tag_50x_NameAndAddress_2, '') <> ''
		SET @tag_value = @tag_value + @tag_50x_NameAndAddress_2 + @CrLf
	IF ISNULL(@tag_50x_NameAndAddress_3, '') <> ''
		SET @tag_value = @tag_value + @tag_50x_NameAndAddress_3 + @CrLf
	IF ISNULL(@tag_50x_NameAndAddress_4, '') <> ''
		SET @tag_value = @tag_value + @tag_50x_NameAndAddress_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '50', @tag_50x_opt, @tag_value)

IF ISNULL(@tag_52x_AccountNumber, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '52', @tag_52x_opt, @tag_52x_AccountNumber + @CrLf)

SET @tag_value = ''
IF @tag_53x_opt = 'A'
	SET @tag_value = @tag_53x_CorAccountAndIso + @CrLf	
IF ISNULL(@tag_53x_AccountNumber, '') <> ''
	SET @tag_value = @tag_value + '/' + @tag_53x_AccountNumber + @CrLf	
IF ISNULL(@tag_53x_NameAndAddress_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_53x_NameAndAddress_1 + @CrLf

	IF ISNULL(@tag_53x_NameAndAddress_2, '') <> ''
		SET @tag_value = @tag_value + @tag_53x_NameAndAddress_2 + @CrLf
	IF ISNULL(@tag_53x_NameAndAddress_3, '') <> ''
		SET @tag_value = @tag_value + @tag_53x_NameAndAddress_3 + @CrLf
	IF ISNULL(@tag_53x_NameAndAddress_4, '') <> ''
		SET @tag_value = @tag_value + @tag_53x_NameAndAddress_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '53', @tag_53x_opt, @tag_value)

SET @tag_value = ''
IF ISNULL(@tag_56x_AccountNumber, '') <> ''
	SET @tag_value = @tag_56x_AccountNumber + @CrLf	
IF ISNULL(@tag_56x_NameAndAddress_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_56x_NameAndAddress_1 + @CrLf

	IF ISNULL(@tag_56x_NameAndAddress_2, '') <> ''
		SET @tag_value = @tag_value + @tag_56x_NameAndAddress_2 + @CrLf
	IF ISNULL(@tag_56x_NameAndAddress_3, '') <> ''
		SET @tag_value = @tag_value + @tag_56x_NameAndAddress_3 + @CrLf
	IF ISNULL(@tag_56x_NameAndAddress_4, '') <> ''
		SET @tag_value = @tag_value + @tag_56x_NameAndAddress_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '56', @tag_56x_opt, @tag_value)

SET @tag_value = ''
IF ISNULL(@tag_57x_AccountNumber, '') <> ''
	SET @tag_value = @tag_57x_AccountNumber + @CrLf	
IF ISNULL(@tag_57x_NameAndAddress_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_57x_NameAndAddress_1 + @CrLf

	IF ISNULL(@tag_57x_NameAndAddress_2, '') <> ''
		SET @tag_value = @tag_value + @tag_57x_NameAndAddress_2 + @CrLf
	IF ISNULL(@tag_57x_NameAndAddress_3, '') <> ''
		SET @tag_value = @tag_value + @tag_57x_NameAndAddress_3 + @CrLf
	IF ISNULL(@tag_57x_NameAndAddress_4, '') <> ''
		SET @tag_value = @tag_value + @tag_57x_NameAndAddress_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '57', @tag_57x_opt, @tag_value)

SET @tag_value = ''
IF ISNULL(@tag_59x_AccountNumber, '') <> ''
	SET @tag_value = CASE WHEN LEFT(@tag_59x_AccountNumber, 1) = '/' THEN '' ELSE '/' END + @tag_59x_AccountNumber + @CrLf	
IF ISNULL(@tag_59x_NameAndAddress_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_59x_NameAndAddress_1 + @CrLf

	IF ISNULL(@tag_59x_NameAndAddress_2, '') <> ''
		SET @tag_value = @tag_value + @tag_59x_NameAndAddress_2 + @CrLf
	IF ISNULL(@tag_59x_NameAndAddress_3, '') <> ''
		SET @tag_value = @tag_value + @tag_59x_NameAndAddress_3 + @CrLf
	IF ISNULL(@tag_59x_NameAndAddress_4, '') <> ''
		SET @tag_value = @tag_value + @tag_59x_NameAndAddress_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '59', NULL, @tag_value)


SET @tag_value = ''
IF ISNULL(@tag_70_Str35_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_70_Str35_1 + @CrLf

	IF ISNULL(@tag_70_Str35_2, '') <> ''
		SET @tag_value = @tag_value + @tag_70_Str35_2 + @CrLf
	IF ISNULL(@tag_70_Str35_3, '') <> ''
		SET @tag_value = @tag_value + @tag_70_Str35_3 + @CrLf
	IF ISNULL(@tag_70_Str35_4, '') <> ''
		SET @tag_value = @tag_value + @tag_70_Str35_4 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '70', NULL, @tag_value)

IF ISNULL(@tag_71A, '') <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '71', 'A', @tag_71A + @CrLf)

SET @tag_value = ''

EXEC @r = impexp.swift_message_builder_on_user_tag72
	@doc_rec_id = @doc_rec_id,
	@tag_72_Str35_1 = @tag_72_Str35_1 OUTPUT,
	@tag_72_Str35_2 = @tag_72_Str35_2 OUTPUT,
	@tag_72_Str35_3 = @tag_72_Str35_3 OUTPUT,
	@tag_72_Str35_4 = @tag_72_Str35_4 OUTPUT,
	@tag_72_Str35_5 = @tag_72_Str35_5 OUTPUT,
	@tag_72_Str35_6 = @tag_72_Str35_6 OUTPUT

IF @r <> 0 OR @@ERROR <> 0
BEGIN
	DELETE FROM impexp.SWIFT_MESSAGE_HELPER WHERE DOC_REC_ID = @doc_rec_id	
	RETURN 1
END


IF ISNULL(@tag_72_Str35_1, '') <> ''
BEGIN
	SET @tag_value = @tag_value + @tag_72_Str35_1 + @CrLf

	IF ISNULL(@tag_72_Str35_2, '') <> ''
		SET @tag_value = @tag_value + @tag_72_Str35_2 + @CrLf
	IF ISNULL(@tag_72_Str35_3, '') <> ''
		SET @tag_value = @tag_value + @tag_72_Str35_3 + @CrLf
	IF ISNULL(@tag_72_Str35_4, '') <> ''
		SET @tag_value = @tag_value + @tag_72_Str35_4 + @CrLf
	IF ISNULL(@tag_72_Str35_5, '') <> ''
		SET @tag_value = @tag_value + @tag_72_Str35_5 + @CrLf
	IF ISNULL(@tag_72_Str35_6, '') <> ''
		SET @tag_value = @tag_value + @tag_72_Str35_6 + @CrLf
END
IF @tag_value <> ''
	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '72', NULL, @tag_value)

EXEC @r = impexp.swift_message_builder_on_user @doc_rec_id = @doc_rec_id

IF @r <> 0 OR @@ERROR <> 0
BEGIN
	DELETE FROM impexp.SWIFT_MESSAGE_HELPER WHERE DOC_REC_ID = @doc_rec_id	
	RETURN 1
END


SELECT @tag_value = TAG_VALUE
FROM impexp.SWIFT_MESSAGE_HELPER
WHERE DOC_REC_ID = @doc_rec_id AND TAG = '{1'

SET @swift_msg = @MsgBegin + '{1' + @tag_value

SELECT @tag_value = TAG_VALUE
FROM impexp.SWIFT_MESSAGE_HELPER
WHERE DOC_REC_ID = @doc_rec_id AND TAG = '{2'

SET @swift_msg = @swift_msg + '{2' + @tag_value

SELECT @tag_value = TAG_VALUE
FROM impexp.SWIFT_MESSAGE_HELPER
WHERE DOC_REC_ID = @doc_rec_id AND TAG = '{4'

SET @swift_msg = @swift_msg + '{4' + @tag_value

DELETE FROM impexp.SWIFT_MESSAGE_HELPER WHERE DOC_REC_ID = @doc_rec_id AND TAG IN ('{1', '{2', '{4')

SELECT @swift_msg = @swift_msg + ':' + TAG + LTRIM(ISNULL(OPT, '')) + ':' + TAG_VALUE
FROM impexp.SWIFT_MESSAGE_HELPER
WHERE DOC_REC_ID = @doc_rec_id
ORDER BY TAG

SET @swift_msg = @swift_msg + '-}' + @MsgEnd + @CrLf 

DELETE FROM impexp.SWIFT_MESSAGE_HELPER WHERE DOC_REC_ID = @doc_rec_id

RETURN (0)
GO
