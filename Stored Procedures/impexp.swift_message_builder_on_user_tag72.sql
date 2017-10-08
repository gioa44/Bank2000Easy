SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE PROCEDURE [impexp].[swift_message_builder_on_user_tag72]
	@doc_rec_id int,
	@tag_72_Str35_1 varchar(35) OUTPUT,
	@tag_72_Str35_2 varchar(35) OUTPUT,
	@tag_72_Str35_3 varchar(35) OUTPUT,
	@tag_72_Str35_4 varchar(35) OUTPUT,
	@tag_72_Str35_5 varchar(35) OUTPUT,
	@tag_72_Str35_6 varchar(35) OUTPUT
AS

DECLARE
	@code varchar(35),
	@stub_str varchar(35)

DECLARE
	@iso						char(3),
	@correspondent_bank_id		int,
	@receiver_institution_code	varchar(37),
	@det_of_charg				char(3),

	@intermed_bank_code2		varchar(37),
	@intermed_bank_name2		varchar(100),
	@extra_info					varchar(255),
	@extra_info_descrip			bit

SELECT
	@correspondent_bank_id		= CORRESPONDENT_BANK_ID,
	@det_of_charg				= UPPER(DET_OF_CHARG),

	@intermed_bank_code2		= UPPER(INTERMED_BANK_CODE2),
	@intermed_bank_name2		= UPPER(INTERMED_BANK_NAME2),
	@extra_info					= UPPER(EXTRA_INFO),
	@extra_info_descrip			= EXTRA_INFO_DESCRIP
FROM impexp.DOCS_OUT_SWIFT (NOLOCK)
WHERE DOC_REC_ID = @doc_rec_id

SET @code = ''
SET @tag_72_Str35_1 = ''
SET @tag_72_Str35_2 = ''
SET @tag_72_Str35_3 = ''
SET @tag_72_Str35_4 = ''
SET @tag_72_Str35_5 = ''
SET @tag_72_Str35_6 = ''

IF LTRIM(RTRIM(ISNULL(@intermed_bank_code2, ''))) <> ''
	SET @tag_72_Str35_1 = '/IBK/' + @intermed_bank_code2

IF UPPER(SUBSTRING(@receiver_institution_code, 1, 8)) = 'DUTDEFF'
	AND @iso = 'EUR' AND @det_of_charg = 'SHA'
BEGIN
	IF @tag_72_Str35_1 = '' 
		SET @tag_72_Str35_1 = '/COB/'
	ELSE
		SET @tag_72_Str35_2 = '/COB/'
END

IF UPPER(SUBSTRING(@receiver_institution_code, 1, 8)) = 'BKTRUS33'
	AND @iso = 'USD' AND @det_of_charg = 'OUR'
BEGIN
	IF @tag_72_Str35_1 = '' 
		SET @tag_72_Str35_1 = '/OUROUR/'
	ELSE
		SET @tag_72_Str35_2 = '/OUROUR/'
END

IF @extra_info_descrip = 1
BEGIN
--	SET @code = '/ACC/RFB/CONTINUED' /* –– ეს არის TBC მოდელი */
	SET @code = '/BNF/CONTINUED' /* –– ეს არის BANK Republic მოდელი */
END

EXEC impexp.swift_break_string_tag72
	@str = @extra_info,
	@code = @code,
	@sw_str_35_1 = @tag_72_Str35_1 OUTPUT,
	@sw_str_35_2 = @tag_72_Str35_2 OUTPUT,
	@sw_str_35_3 = @tag_72_Str35_3 OUTPUT,
	@sw_str_35_4 = @tag_72_Str35_4 OUTPUT,
	@sw_str_35_5 = @tag_72_Str35_5 OUTPUT,
	@sw_str_35_6 = @tag_72_Str35_6 OUTPUT

RETURN 0
GO
