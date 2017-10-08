SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [impexp].[swift_message_builder_on_user]
	@doc_rec_id int
AS
--მხოლოდ TBC

DELETE FROM impexp.SWIFT_MESSAGE_HELPER
WHERE DOC_REC_ID = @doc_rec_id AND TAG = '33'

DECLARE	@CrLf char(2)
SET @CrLf = CHAR(0xD) + CHAR(0xA)
DECLARE
	@iso						char(3),
	@correspondent_bank_id		int,
	@receiver_institution_code	varchar(37),
	@det_of_charg				char(3)
	

SELECT
	@correspondent_bank_id		= CORRESPONDENT_BANK_ID,
	@det_of_charg				= UPPER(DET_OF_CHARG)
FROM impexp.DOCS_OUT_SWIFT (NOLOCK)
WHERE DOC_REC_ID = @doc_rec_id

SELECT @receiver_institution_code = BIC
FROM dbo.CORRESPONDENT_BANKS (NOLOCK)
WHERE REC_ID = @correspondent_bank_id

IF UPPER(SUBSTRING(@receiver_institution_code, 1, 8)) IN ('CITIUS33', 'BKTRUS33', 'CHASUS33')
	AND @iso = 'USD' AND @det_of_charg = 'SHA'
BEGIN
	DELETE FROM impexp.SWIFT_MESSAGE_HELPER
	WHERE DOC_REC_ID = @doc_rec_id AND TAG = '71'

	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '71', 'A', 'OUR' + @CrLf)
END

IF UPPER(SUBSTRING(@receiver_institution_code, 1, 8)) = 'DUTDEFF'
	AND @iso = 'EUR' AND @det_of_charg = 'SHA'
BEGIN
	DELETE FROM impexp.SWIFT_MESSAGE_HELPER
	WHERE DOC_REC_ID = @doc_rec_id AND TAG = '71'

	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '71', 'A', 'OUR' + @CrLf)
END

IF UPPER(SUBSTRING(@receiver_institution_code, 1, 8)) = 'DRESDEFF'
	AND @iso = 'EUR' AND @det_of_charg = 'SHA'
BEGIN
	DELETE FROM impexp.SWIFT_MESSAGE_HELPER
	WHERE DOC_REC_ID = @doc_rec_id AND TAG = '71'

	INSERT INTO impexp.SWIFT_MESSAGE_HELPER(DOC_REC_ID, TAG, OPT, TAG_VALUE)
	VALUES(@doc_rec_id, '71', 'A', 'OUR' + @CrLf)
END

--END მხოლოდ TBC

RETURN 0
GO
