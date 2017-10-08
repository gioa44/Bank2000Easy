SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[SWIFT_SEND_IN_MODULE]
	@rec_id int,
	@user_id int
AS

SET NOCOUNT ON

DECLARE
	@op_num int,
	@date_add smalldatetime,
	@doc_date smalldatetime,
	@doc_date_in_doc smalldatetime,
	@iso TISO,
	@amount TAMOUNT,
	@amount_equ TAMOUNT,
	@doc_num int,
	@op_code TOPCODE,
	@debit TACCOUNT,
	@credit TACCOUNT,
	@rec_state tinyint,
	@bnk_cli_id int,
	@descrip varchar(150),
	@parent_rec_id int,
	@owner int,
	@doc_type smallint,
	@account_extra TACCOUNT,
	@prog_id int,
	@foreign_id int,
	@channel_id int,
	@dept_no int,
	@is_suspicious bit,
	@sender_bank_code TINTBANKCODE,
	@sender_bank_name varchar(100),
	@sender_acc TINTACCOUNT,
	@sender_acc_name varchar(100),
	@receiver_bank_code TINTBANKCODE,
	@receiver_bank_name varchar(100),
	@receiver_acc TINTACCOUNT,
	@receiver_acc_name varchar(100),
	@intermed_bank_code TINTBANKCODE,
	@intermed_bank_name varchar(100),
	@receiver_info varchar(255),
	@receiver_info_1 varchar(35),
	@receiver_info_2 varchar(35),
	@receiver_info_3 varchar(35),
	@receiver_info_4 varchar(35),
	@sender_tax_code varchar(11),
	@receiver_tax_code varchar(11),
	@first_name varchar(50),
	@last_name varchar(50),
	@fathers_name varchar(50),
	@birth_date smalldatetime,
	@birth_place varchar(100),
	@address_jur varchar(100),
	@address_fact varchar(100),
	@country char(2),
	@passport_type_id tinyint,
	@passport varchar(50),
	@personal_id varchar(20),
	@ref_num varchar(32),
	@cor_bank_code TINTBANKCODE,
	@cor_account varchar(35),
	@cor_bank_name varchar(100),
	@address_lat varchar(100),
	@swift_rec_state tinyint,
	@swift_add_date smalldatetime,
	@swift_rec_id varchar(100),
	@receiver_institution TINTBANKCODE,
	@receiver_institution_name varchar(100),
	@swift_op_code varchar(55),
	@doc_date_str char(8),
	@sender_acc_swift varchar(50),
	@sender_descrip varchar(100),
	@descrip_ext varchar(255),
	@fin_date smalldatetime,
	@fin_account TACCOUNT,
	@fin_acc_name varchar(100),
	@fin_amount TAMOUNT,
	@fin_iso TISO,
	@fin_doc_rec_id int,
	@det_of_charg char(3)

SELECT @op_num = OP_NUM,
	@doc_date = DOC_DATE,
	@doc_date_in_doc = DOC_DATE_IN_DOC,
	@iso = ISO,
	@amount = AMOUNT,
	@amount_equ = AMOUNT_EQU,
	@doc_num = DOC_NUM,
	@op_code = OP_CODE,
	@debit = DEBIT,
	@credit = CREDIT,
	@rec_state = REC_STATE,
	@bnk_cli_id = BNK_CLI_ID,
	@descrip = DESCRIP,
	@parent_rec_id = PARENT_REC_ID,
	@owner = [OWNER],
	@doc_type = DOC_TYPE,
	@account_extra = ACCOUNT_EXTRA,
	@foreign_id = FOREIGN_ID,
	@channel_id = CHANNEL_ID,
	@dept_no = DEPT_NO,
	@is_suspicious = IS_SUSPICIOUS,
	@sender_bank_code = SENDER_BANK_CODE,
	@sender_bank_name = SENDER_BANK_NAME,
	@sender_acc = SENDER_ACC,
	@sender_acc_name = SENDER_ACC_NAME,
	@receiver_bank_code = RECEIVER_BANK_CODE,
	@receiver_bank_name = RECEIVER_BANK_NAME,
	@receiver_acc = RECEIVER_ACC,
	@receiver_acc_name = RECEIVER_ACC_NAME,
	@intermed_bank_code = INTERMED_BANK_CODE,
	@intermed_bank_name = INTERMED_BANK_NAME,
	@receiver_info = RECEIVER_INFO,
	@sender_tax_code = SENDER_TAX_CODE,
	@receiver_tax_code = RECEIVER_TAX_CODE,
	@first_name = FIRST_NAME,
	@last_name = LAST_NAME,
	@fathers_name = FATHERS_NAME,
	@birth_date = BIRTH_DATE,
	@birth_place = BIRTH_PLACE,
	@address_jur = ADDRESS_JUR,
	@address_fact = ADDRESS_FACT,
	@country = COUNTRY,
	@passport_type_id = PASSPORT_TYPE_ID,
	@passport = PASSPORT,
	@personal_id = PERSONAL_ID,
	@ref_num = REF_NUM,
	@cor_bank_code = COR_BANK_CODE,
	@cor_bank_name = COR_BANK_NAME,
	@address_lat = ADDRESS_LAT
FROM
	dbo.DOCS_VALPLAT (NOLOCK)
WHERE REC_ID = @rec_id

SET @swift_rec_id = convert(varchar(20),@rec_id) + '-' + @sender_bank_code
SET	@swift_op_code = convert(varchar(30),ltrim((isnull(@op_code,'') + isnull(convert(varchar(25),@account_extra),''))))
SET	@doc_date_str = dbo.FN_SWIFT_GET_DATE_STR(@doc_date)
SET	@sender_acc_swift = '/' + @sender_acc

SET @date_add = (SELECT TOP 1 TIME_OF_CHANGE FROM dbo.DOC_CHANGES WHERE DOC_REC_ID=@rec_id ORDER BY REC_ID)
SET	@prog_id = 0
SET @cor_account = NULL

SET	@receiver_info_1 = NULL
SET	@receiver_info_2 = NULL
SET	@receiver_info_3 = NULL
SET	@receiver_info_4 = NULL

SET	@swift_rec_state = 0
SET	@swift_add_date = getdate()
SET	@receiver_institution = NULL
SET	@receiver_institution_name = NULL
SET	@sender_descrip = NULL
SET	@descrip_ext = NULL
SET	@fin_date = getdate()
SET	@fin_account = NULL
SET	@fin_acc_name = NULL
SET	@fin_amount = @amount
SET	@fin_iso = @iso
SET	@fin_doc_rec_id = NULL
SET	@det_of_charg = NULL

SET @sender_descrip = ISNULL(@first_name, '') + CASE WHEN (@first_name IS NULL) OR (@last_name IS NULL) THEN '' ELSE '' END + ISNULL(@last_name, '')

EXEC dbo.ON_USER_SWIFT_SEND_IN_MODULE
	@user_id=@user_id,
	@rec_id=@rec_id,
	@op_num=@op_num OUTPUT ,
	@date_add=@date_add OUTPUT ,
	@doc_date=@doc_date OUTPUT ,
	@doc_date_in_doc=@doc_date_in_doc OUTPUT ,
	@iso=@iso OUTPUT ,
	@amount=@amount OUTPUT ,
	@amount_equ=@amount_equ OUTPUT ,
	@doc_num=@doc_num OUTPUT ,
	@op_code=@op_code OUTPUT ,
	@debit=@debit OUTPUT ,
	@credit=@credit OUTPUT ,
	@rec_state=@rec_state OUTPUT ,
	@bnk_cli_id=@bnk_cli_id OUTPUT ,
	@descrip=@descrip OUTPUT ,
	@parent_rec_id=@parent_rec_id OUTPUT ,
	@owner=@owner OUTPUT ,
	@doc_type=@doc_type OUTPUT ,
	@account_extra=@account_extra OUTPUT ,
	@prog_id=@prog_id OUTPUT ,
	@foreign_id=@foreign_id OUTPUT ,
	@channel_id=@channel_id OUTPUT ,
	@dept_no=@dept_no OUTPUT ,
	@is_suspicious=@is_suspicious OUTPUT ,
	@sender_bank_code=@sender_bank_code OUTPUT ,
	@sender_bank_name=@sender_bank_name OUTPUT ,
	@sender_acc=@sender_acc OUTPUT ,
	@sender_acc_name=@sender_acc_name OUTPUT ,
	@receiver_bank_code=@receiver_bank_code OUTPUT ,
	@receiver_bank_name=@receiver_bank_name OUTPUT ,
	@receiver_acc=@receiver_acc OUTPUT ,
	@receiver_acc_name=@receiver_acc_name OUTPUT ,
	@intermed_bank_code=@intermed_bank_code OUTPUT ,
	@intermed_bank_name=@intermed_bank_name OUTPUT ,
	@receiver_info=@receiver_info OUTPUT ,
	@receiver_info_1=@receiver_info_1 OUTPUT ,
	@receiver_info_2=@receiver_info_2 OUTPUT ,
	@receiver_info_3=@receiver_info_3 OUTPUT ,
	@receiver_info_4=@receiver_info_4 OUTPUT ,
	@sender_tax_code=@sender_tax_code OUTPUT ,
	@receiver_tax_code=@receiver_tax_code OUTPUT ,
	@first_name=@first_name OUTPUT ,
	@last_name=@last_name OUTPUT ,
	@fathers_name=@fathers_name OUTPUT ,
	@birth_date=@birth_date OUTPUT ,
	@birth_place=@birth_place OUTPUT ,
	@address_jur=@address_jur OUTPUT ,
	@address_fact=@address_fact OUTPUT ,
	@country=@country OUTPUT ,
	@passport_type_id=@passport_type_id OUTPUT ,
	@passport=@passport OUTPUT ,
	@personal_id=@personal_id OUTPUT ,
	@ref_num=@ref_num OUTPUT ,
	@cor_bank_code=@cor_bank_code OUTPUT ,
	@cor_account=@cor_account OUTPUT ,
	@cor_bank_name=@cor_bank_name OUTPUT ,
	@address_lat=@address_lat OUTPUT ,
	@swift_rec_state=@swift_rec_state OUTPUT ,
	@swift_add_date=@swift_add_date OUTPUT ,
	@swift_rec_id=@swift_rec_id OUTPUT ,
	@receiver_institution=@receiver_institution OUTPUT ,
	@receiver_institution_name=@receiver_institution_name OUTPUT ,
	@swift_op_code=@swift_op_code OUTPUT ,
	@doc_date_str=@doc_date_str OUTPUT ,
	@sender_acc_swift=@sender_acc_swift OUTPUT ,
	@sender_descrip=@sender_descrip OUTPUT ,
	@descrip_ext=@descrip_ext OUTPUT ,
	@fin_date=@fin_date OUTPUT ,
	@fin_account=@fin_account OUTPUT ,
	@fin_acc_name=@fin_acc_name OUTPUT ,
	@fin_amount=@fin_amount OUTPUT ,
	@fin_iso=@fin_iso OUTPUT ,
	@fin_doc_rec_id=@fin_doc_rec_id OUTPUT ,
	@det_of_charg=@det_of_charg OUTPUT


INSERT dbo.SWIFT_DOCS_IN(OP_NUM, REC_ID, DATE_ADD, DOC_DATE, DOC_DATE_IN_DOC, ISO, AMOUNT, AMOUNT_EQU, DOC_NUM, OP_CODE, DEBIT, CREDIT, REC_STATE, BNK_CLI_ID, DESCRIP, PARENT_REC_ID, [OWNER], DOC_TYPE, ACCOUNT_EXTRA, PROG_ID, FOREIGN_ID, CHANNEL_ID, DEPT_NO, IS_SUSPICIOUS, SENDER_BANK_CODE, SENDER_BANK_NAME, SENDER_ACC, SENDER_ACC_NAME, RECEIVER_BANK_CODE, RECEIVER_BANK_NAME, RECEIVER_ACC, RECEIVER_ACC_NAME, INTERMED_BANK_CODE, INTERMED_BANK_NAME, RECEIVER_INFO, RECEIVER_INFO_1, RECEIVER_INFO_2, RECEIVER_INFO_3, RECEIVER_INFO_4, SENDER_TAX_CODE, RECEIVER_TAX_CODE, FIRST_NAME, LAST_NAME, FATHERS_NAME, BIRTH_DATE, BIRTH_PLACE, ADDRESS_JUR, ADDRESS_FACT, COUNTRY, PASSPORT_TYPE_ID, PASSPORT, PERSONAL_ID, REF_NUM, COR_BANK_CODE, COR_ACCOUNT, COR_BANK_NAME, ADDRESS_LAT, SWIFT_REC_STATE, SWIFT_ADD_DATE, SWIFT_REC_ID, RECEIVER_INSTITUTION, RECEIVER_INSTITUTION_NAME, SWIFT_OP_CODE, DOC_DATE_STR, SENDER_ACC_SWIFT, SENDER_DESCRIP, DESCRIP_EXT, FIN_DATE, FIN_ACCOUNT, FIN_ACC_NAME, FIN_AMOUNT, FIN_ISO, FIN_DOC_REC_ID, DET_OF_CHARG)
VALUES(@op_num, @rec_id, @date_add, @doc_date, @doc_date_in_doc, @iso, @amount, @amount_equ, @doc_num, @op_code, @debit, @credit, @rec_state, @bnk_cli_id, @descrip, @parent_rec_id, @owner, @doc_type, @account_extra, @prog_id, @foreign_id, @channel_id, @dept_no, @is_suspicious, @sender_bank_code, @sender_bank_name, @sender_acc, @sender_acc_name, @receiver_bank_code, @receiver_bank_name, @receiver_acc, @receiver_acc_name, @intermed_bank_code, @intermed_bank_name, @receiver_info, @receiver_info_1, @receiver_info_2, @receiver_info_3, @receiver_info_4, @sender_tax_code, @receiver_tax_code, @first_name, @last_name, @fathers_name, @birth_date, @birth_place, @address_jur, @address_fact, @country, @passport_type_id, @passport, @personal_id, @ref_num, @cor_bank_code, @cor_account, @cor_bank_name, @address_lat, @swift_rec_state, @swift_add_date, @swift_rec_id, @receiver_institution, @receiver_institution_name, @swift_op_code, @doc_date_str, @sender_acc_swift, @sender_descrip, @descrip_ext, @fin_date, @fin_account, @fin_acc_name, @fin_amount, @fin_iso, @fin_doc_rec_id, @det_of_charg)

IF @@ERROR<>0 BEGIN IF @@TRANCOUNT>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ 1.',16,1) END RETURN END
INSERT INTO SWIFT_DOCS_IN_CHANGES (DOC_REC_ID,USER_ID,DESCRIP) VALUES (@rec_id,@user_id,'ÓÀÁÖÈÉ ÌÉÙÄÁÖËÉÀ ÛÖÀËÄÃÖÒ ÌÏÃÖËÛÉ')
IF @@ERROR<>0 BEGIN ROLLBACK RAISERROR ('ÛÄÝÃÏÌÀ 2.',16,1) RETURN END
GO
