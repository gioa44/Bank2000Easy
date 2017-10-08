SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [impexp].[check_send_doc_prepared_swift]
	@doc_rec_id int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@ref_num varchar(32),
	@correspondent_bank_id int,
	@sender_address_lat varchar(100),
	@det_of_charg varchar(3),
	@receiver_acc varchar(37),
	@receiver_acc_name varchar(100),
	@intermed_bank_code TINTBANKCODE,
	@intermed_bank_name varchar(100),
	@intermed_bank_code2 TINTBANKCODE,
	@intermed_bank_name2 varchar(100)
	

SELECT @ref_num = LTRIM(RTRIM(REF_NUM)), @correspondent_bank_id = CORRESPONDENT_BANK_ID, @sender_address_lat = LTRIM(RTRIM(SENDER_ADDRESS_LAT)), @det_of_charg = DET_OF_CHARG,
	@receiver_acc = LTRIM(RTRIM(RECEIVER_ACC)), @receiver_acc_name = LTRIM(RTRIM(RECEIVER_ACC_NAME)),
	@intermed_bank_code = LTRIM(RTRIM(INTERMED_BANK_CODE)), @intermed_bank_name = LTRIM(RTRIM(INTERMED_BANK_NAME)),
	@intermed_bank_code2 = LTRIM(RTRIM(INTERMED_BANK_CODE2)), @intermed_bank_name2 = LTRIM(RTRIM(INTERMED_BANK_NAME2))

FROM impexp.DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

IF ISNULL(@ref_num, '') = ''
BEGIN 
	RAISERROR ('"Sender’s Reference" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF @correspondent_bank_id IS NULL
BEGIN 
	RAISERROR ('"ÌÏÊÏÒÄÓÐÏÍÃÄÍÔÏ ÁÀÍÊÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF ISNULL(@sender_address_lat, '') = ''
BEGIN 
	RAISERROR ('"Sender’s Address" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF @det_of_charg IS NULL
BEGIN 
	RAISERROR ('"Details of Charges" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF ISNULL(@receiver_acc, '') = ''
BEGIN 
	RAISERROR ('"ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF ISNULL(@receiver_acc_name, '') = ''
BEGIN 
	RAISERROR ('"ÌÉÌÙÄÁÉÓ ÀÍÂÀÒÉÛÉÓ ÃÀÓÀáÄËÄÁÀ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END

IF ISNULL(@intermed_bank_code, '') = '' AND ISNULL(@intermed_bank_code2, '') <> ''
BEGIN 
	RAISERROR ('"ÛÖÀÌÀÅÀËÉ ÁÀÍÊÉ 2" ÀÒÓÄÁÏÁÓ ÃÀ "ÛÖÀÌÀÅÀËÉ ÁÀÍÊÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ!!!',16,1)
	RETURN 1
END
RETURN 0
GO
