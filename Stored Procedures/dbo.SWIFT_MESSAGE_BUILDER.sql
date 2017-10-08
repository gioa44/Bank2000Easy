SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SWIFT_MESSAGE_BUILDER]
	@rec_id int
AS
SET NOCOUNT ON 
DECLARE
	@swift_msg varchar(4000) 
DECLARE
	@MsgBegin char(1),
	@MsgEnd char(1),
	@Cr char(1),
	@Lf char(1),
	@CrLf char(2),
	@MsgType char(3),
	@oInputLT TINTBANKCODE

SET @MsgBegin = CHAR(0x1)
SET @MsgEnd = CHAR(0x3)
SET @Cr = CHAR(0xD)
SET @Lf = CHAR(0xA)
SET @CrLf = @Cr + @Lf
SET @MsgType = '103'


DECLARE
	@check bit

DECLARE
	@ref_num					varchar(32),
	@doc_date					smalldatetime,
	@amount						TAMOUNT,
	@iso						TISO,
	@swift_iso					TISO,
	@sender_bank_code			TINTBANKCODE,
	@sender_bank_name			varchar(100),
	@sender_acc					varchar(37),
	@sender_acc_name			varchar(100),
	@receiver_bank_code			TINTBANKCODE,
	@receiver_bank_name			varchar(100),
	@receiver_acc				varchar(37),
	@receiver_acc_name			varchar(100),
	@cor_bank_code				TINTBANKCODE,
	@cor_bank_name				varchar(100),
	@cor_account				varchar(35),
	@receiver_institution		TINTBANKCODE,
	@intermed_bank_code			TINTBANKCODE,
	@intermed_bank_name			varchar(100),

	@det_of_payment				varchar(150),
	@det_of_charg				char(3),
	@receiver_info_1			varchar(35),
	@receiver_info_2			varchar(35),
	@receiver_info_3			varchar(35),
	@receiver_info_4			varchar(35),
	@receiver_info_5			varchar(35),
	@receiver_info_6			varchar(35)

SELECT
	@ref_num					= REF_NUM,
	@doc_date					= DOC_DATE,
	@amount						= AMOUNT,
	@iso						= ISO,
	@sender_bank_code			= UPPER(SENDER_BANK_CODE),
	@sender_bank_name			= UPPER(SENDER_BANK_NAME),
	@sender_acc					= SENDER_ACC,
	@sender_acc_name			= UPPER(SENDER_ACC_NAME),
	@receiver_bank_code			= UPPER(RECEIVER_BANK_CODE),
	@receiver_bank_name			= UPPER(RECEIVER_BANK_NAME),
	@receiver_acc				= RECEIVER_ACC,
	@receiver_acc_name			= UPPER(RECEIVER_ACC_NAME),
	@cor_bank_code				= UPPER(COR_BANK_CODE),
	@cor_bank_name				= UPPER(COR_BANK_NAME),
	@cor_account				= COR_ACCOUNT,
	@receiver_institution		= UPPER(RECEIVER_INSTITUTION),
	@intermed_bank_code			= UPPER(INTERMED_BANK_CODE),
	@intermed_bank_name			= UPPER(INTERMED_BANK_NAME),


	@det_of_payment				= UPPER(DESCRIP),
	@det_of_charg				= UPPER(DET_OF_CHARG),
	@receiver_info_1			= UPPER(RECEIVER_INFO_1),
	@receiver_info_2			= UPPER(RECEIVER_INFO_2),
	@receiver_info_3			= UPPER(RECEIVER_INFO_3),
	@receiver_info_4			= UPPER(RECEIVER_INFO_4),
	@receiver_info_5			= UPPER(RECEIVER_INFO_5),
	@receiver_info_6			= UPPER(RECEIVER_INFO_6)

FROM
	dbo.SWIFT_DOCS_IN (NOLOCK)
WHERE REC_ID = @rec_id

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
	@tag_52x_AccountNumber TINTBANKCODE,

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

SET @tag_20 = @ref_num
SET @tag_23B = 'CRED'
SET @swift_iso = CASE
		WHEN @iso = 'RUR' THEN 'RUB'
		WHEN @iso = 'AVD' THEN 'AUD'
		ELSE @iso
	END 
SET @tag_32A = SUBSTRING(convert(char(4), DATEPART(yy, @doc_date)), 3, 2) + REPLICATE('0', 2 - LEN(convert(varchar(2), DATEPART(mm, @doc_date)))) + convert(varchar(2), DATEPART(mm, @doc_date)) + REPLICATE('0', 2 - LEN(convert(varchar(2), DATEPART(dd, @doc_date)))) + convert(varchar(2), DATEPART(dd, @doc_date))
SET @tag_32A = @tag_32A + @swift_iso
/*IF convert(int, @amount) = @amount
	SET @tag_32A = @tag_32A + convert(varchar(15), convert(int, @amount)) + ','
ELSE*/ -- es piroba dasazustebelia
SET @tag_32A = @tag_32A + REPLACE(convert(varchar(15), @amount), '.', ',')

SET @tag_33B = @swift_iso
/*IF convert(int, @amount) = @amount
	SET @tag_33B = @tag_33B + convert(varchar(15), convert(int, @amount)) + ','
ELSE*/ -- es piroba dasazustebelia
SET @tag_33B = @tag_33B + REPLACE(convert(varchar(15), @amount), '.', ',')

SET @tag_50x_opt = 'K'
SET @tag_50x_AccountNumber = @sender_acc
EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
	@str = @sender_acc_name,
	@sw_str_35_1 = @tag_50x_NameAndAddress_1 OUTPUT,
	@sw_str_35_2 = @tag_50x_NameAndAddress_2 OUTPUT,
	@sw_str_35_3 = @tag_50x_NameAndAddress_3 OUTPUT,
	@sw_str_35_4 = @tag_50x_NameAndAddress_4 OUTPUT

SET @tag_52x_opt = 'A'
SET @tag_52x_AccountNumber = SUBSTRING(@sender_bank_code, 1, 8)

IF ISNULL(@cor_bank_code, '') <> ''
	SET @tag_53x_AccountNumber = @cor_bank_code
IF ISNULL(@cor_account, '') <> ''
BEGIN
	SET @tag_53x_opt = 'A'
	SET @tag_53x_CorAccountAndIso = @cor_account
END
ELSE
BEGIN
	SET @tag_53x_opt = 'D'
	IF ISNULL(@cor_bank_name, '') <> ''
	BEGIN
		EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
			@str = @cor_bank_name,
			@sw_str_35_1 = @tag_53x_NameAndAddress_1 OUTPUT,
			@sw_str_35_2 = @tag_53x_NameAndAddress_2 OUTPUT,
			@sw_str_35_3 = @tag_53x_NameAndAddress_3 OUTPUT,
			@sw_str_35_4 = @tag_53x_NameAndAddress_4 OUTPUT
	END
END

IF @intermed_bank_code = '.'
BEGIN
	SET @tag_56x_opt = 'D'
	EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
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
	EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
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
	EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
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
	EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
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
		WHEN ISNULL(@receiver_institution, '')	<> '' THEN SUBSTRING(@receiver_institution, 1, 8) + 'XXXX'
		WHEN ISNULL(@cor_bank_code, '')			<> '' THEN SUBSTRING(@cor_bank_code, 1, 8) + 'XXXX'
		WHEN ISNULL(@tag_56x_AccountNumber, '') <> '' THEN SUBSTRING(@tag_56x_AccountNumber, 1, 8) + 'XXXX'
		WHEN ISNULL(@tag_57x_AccountNumber, '') <> '' THEN SUBSTRING(@tag_57x_AccountNumber, 1, 8) + 'XXXX'
		ELSE NULL 
	END

SET @tag_59x_AccountNumber = @receiver_acc
EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
	@str = @receiver_acc_name,
	@sw_str_35_1 = @tag_59x_NameAndAddress_1 OUTPUT,
	@sw_str_35_2 = @tag_59x_NameAndAddress_2 OUTPUT,
	@sw_str_35_3 = @tag_59x_NameAndAddress_3 OUTPUT,
	@sw_str_35_4 = @tag_59x_NameAndAddress_4 OUTPUT

EXEC dbo.SWIFT_BREAK_STRING_STR35_4 
	@str = @det_of_payment,
	@sw_str_35_1 = @tag_70_Str35_1 OUTPUT,
	@sw_str_35_2 = @tag_70_Str35_2 OUTPUT,
	@sw_str_35_3 = @tag_70_Str35_3 OUTPUT,
	@sw_str_35_4 = @tag_70_Str35_4 OUTPUT

SET @tag_71A = @det_of_charg

SET @tag_72_Str35_1 = @receiver_info_1
SET @tag_72_Str35_2 = @receiver_info_2
SET @tag_72_Str35_3 = @receiver_info_3
SET @tag_72_Str35_4 = @receiver_info_4
SET @tag_72_Str35_5 = @receiver_info_5
SET @tag_72_Str35_6 = @receiver_info_6

DECLARE
	@tag_value varchar(255)

DELETE FROM dbo.SWIFT_MESSAGE_HELPER WHERE REC_ID = @rec_id

INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@rec_id, '{1', NULL, ':F01' + @tag_52x_AccountNumber + 'AXXX' + '0000000000' + '}')
INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@rec_id, '{2', NULL, ':I' + @MsgType + @oInputLT + 'N' + '}')
INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
VALUES(@rec_id, '{4', NULL, ':' + @CrLf)

IF ISNULL(@tag_20, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '20', NULL, @tag_20 + @CrLf)
IF ISNULL(@tag_23B, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '23', 'B', @tag_23B + @CrLf)
IF ISNULL(@tag_32A, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '32', 'A', @tag_32A + @CrLf)
IF ISNULL(@tag_33B, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '33', 'B', @tag_33B + @CrLf)


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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '50', @tag_50x_opt, @tag_value)

IF ISNULL(@tag_52x_AccountNumber, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '52', @tag_52x_opt, @tag_52x_AccountNumber + @CrLf)

SET @tag_value = ''
IF ISNULL(@tag_53x_AccountNumber, '') <> ''
	SET @tag_value = '/' + @tag_53x_AccountNumber + @CrLf	
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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '53', @tag_53x_opt, @tag_value)

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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '56', @tag_56x_opt, @tag_value)

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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '57', @tag_57x_opt, @tag_value)

SET @tag_value = ''
IF ISNULL(@tag_59x_AccountNumber, '') <> ''
	SET @tag_value = '/' + @tag_59x_AccountNumber + @CrLf	
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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '59', NULL, @tag_value)


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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '70', NULL, @tag_value)

IF ISNULL(@tag_71A, '') <> ''
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '71', 'A', @tag_71A + @CrLf)

SET @tag_value = ''
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
	INSERT INTO dbo.SWIFT_MESSAGE_HELPER(REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@rec_id, '72', NULL, @tag_value)

EXEC dbo.ON_USER_SWIFT_MESSAGE_BUILDER @rec_id = @rec_id

SELECT @tag_value = TAG_VALUE
FROM dbo.SWIFT_MESSAGE_HELPER
WHERE REC_ID = @rec_id AND TAG = '{1'

SET @swift_msg = @MsgBegin + '{1' + @tag_value

SELECT @tag_value = TAG_VALUE
FROM dbo.SWIFT_MESSAGE_HELPER
WHERE REC_ID = @rec_id AND TAG = '{2'

SET @swift_msg = @swift_msg + '{2' + @tag_value

SELECT @tag_value = TAG_VALUE
FROM dbo.SWIFT_MESSAGE_HELPER
WHERE REC_ID = @rec_id AND TAG = '{4'

SET @swift_msg = @swift_msg + '{4' + @tag_value

DELETE FROM dbo.SWIFT_MESSAGE_HELPER WHERE REC_ID = @rec_id AND TAG IN ('{1', '{2', '{4')

SELECT @swift_msg = @swift_msg + ':' + TAG + LTRIM(ISNULL(OPT, '')) + ':' + TAG_VALUE
FROM SWIFT_MESSAGE_HELPER
WHERE REC_ID = @rec_id
ORDER BY TAG

SET @swift_msg = @swift_msg + '-}' + @MsgEnd + @CrLf 

DELETE FROM dbo.SWIFT_MESSAGE_HELPER WHERE REC_ID = @rec_id

SELECT convert(TEXT, @swift_msg) AS SWIFT_MSG
RETURN (0)
GO
