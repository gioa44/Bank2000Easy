SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [impexp].[docs_out_swift_edit]
	@doc_rec_id int,
	@uid int,
	@user_id int,
    @ref_num  varchar(32),
    @descrip  varchar(150),
    @sender_address_lat varchar(105),
    @receiver_bank_code varchar(37),
    @receiver_bank_name varchar(100),
    @receiver_acc varchar(37),
    @receiver_acc_name varchar(100),
	@receiver_address_lat varchar(105),
    @intermed_bank_code  varchar(37),
    @intermed_bank_name  varchar(100),
    @intermed_bank_code2 varchar(37),
    @intermed_bank_name2 varchar(100),
	@correspondent_bank_id int,
    @extra_info varchar(255),
    @extra_info_descrip bit,
    @det_of_charg char(3)
AS

DECLARE
	@rec_uid int,
	@doc_date smalldatetime,
    @portion_date  smalldatetime,
    @portion int,
    @old_flags  int,
    @iso  TISO,
    @amount  money,
    @amount_equ  money,
    @sender_bank_code varchar(37),
    @sender_bank_name varchar(100),
    @sender_acc varchar(37),
    @sender_acc_name varchar(100),
    @state  int,
    @swift_flags_1 int,
    @swift_flags_2 int	

BEGIN TRAN

SELECT @rec_uid = UID, @doc_date = DOC_DATE, @portion_date = PORTION_DATE, @portion = PORTION, @old_flags = OLD_FLAGS, @iso = ISO, @amount = AMOUNT, @amount_equ = AMOUNT_EQU,
    @sender_bank_code = SENDER_BANK_CODE, @sender_bank_name = SENDER_BANK_NAME, @sender_acc = SENDER_ACC, @sender_acc_name = SENDER_ACC_NAME,
    @state = [STATE], @swift_flags_1 = SWIFT_FLAGS_1, @swift_flags_2 = SWIFT_FLAGS_2
FROM impexp.DOCS_OUT_SWIFT (UPDLOCK)
WHERE DOC_REC_ID = @doc_rec_id

IF @uid <> ISNULL(@rec_uid, -1)
BEGIN
	ROLLBACK
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

UPDATE impexp.DOCS_OUT_SWIFT
SET UID = UID + 1,
	REF_NUM = @ref_num,
	DESCRIP = @descrip,
	SENDER_ADDRESS_LAT = @sender_address_lat,
	RECEIVER_BANK_CODE = @receiver_bank_code,
	RECEIVER_BANK_NAME = @receiver_bank_name,
	RECEIVER_ACC = @receiver_acc,
	RECEIVER_ACC_NAME = @receiver_acc_name,
	RECEIVER_ADDRESS_LAT = @receiver_address_lat,
	INTERMED_BANK_CODE = @intermed_bank_code,
	INTERMED_BANK_NAME = @intermed_bank_name,
	INTERMED_BANK_CODE2 = @intermed_bank_code2,
	INTERMED_BANK_NAME2 = @intermed_bank_name2,
	CORRESPONDENT_BANK_ID = @correspondent_bank_id,
	EXTRA_INFO = @extra_info,
	EXTRA_INFO_DESCRIP = @extra_info_descrip,
	DET_OF_CHARG = @det_of_charg,
	FINALYZE_DATE = NULL,
	FINALYZE_BANK_ID = @correspondent_bank_id,
	FINALYZE_ACC_ID = NULL,
	FINALYZE_AMOUNT = NULL,
	FINALYZE_ISO = NULL,
	[STATE] = 12, --psUpdated
	SWIFT_FLAGS_1 = @swift_flags_1,
	SWIFT_FLAGS_2 = @swift_flags_2
WHERE DOC_REC_ID = @doc_rec_id and UID = @uid
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_OUT_SWIFT_CHANGES(DOC_REC_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES(@doc_rec_id, @user_id, 5, 'ÓÀÁÖÈÉÓ ÛÄÝÅËÀ (SWIFT ×ÏÒÌÀÔÉ)')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT

SELECT *
FROM impexp.V_DOCS_OUT_SWIFT
WHERE DOC_REC_ID = @doc_rec_id

RETURN 0
GO
