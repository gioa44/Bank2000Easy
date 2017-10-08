SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_AUTHORIZE_SWIFT_DOC]
  @rec_id int,
  @user_id int,
  @new_rec_state tinyint,
  @old_rec_state tinyint
AS
SET NOCOUNT ON

DECLARE 
	@op_num int,
	@doc_date smalldatetime,
	@doc_date_in_doc smalldatetime,
	@doc_type smallint,
	@debit_id int,
	@credit_id int,
    @credit TACCOUNT,
	@iso TISO,
	@amount money,
	@doc_num int,
	@op_code TOPCODE,
	@bnk_cli_id int,
	@descrip varchar(150),
	@owner int,
	@account_extra TACCOUNT,
	@prod_id int,
	@foreign_id int,
	@channel_id int,
	@dept_no int,

	@sender_bank_code TINTBANKCODE,
	@sender_acc TINTACCOUNT,
	@receiver_bank_code TINTBANKCODE,
	@receiver_acc TINTACCOUNT,
	@sender_bank_name varchar(100),
	@receiver_bank_name varchar(100),
	@sender_acc_name varchar(100),
	@receiver_acc_name varchar(100),
	@intermed_bank_code TINTBANKCODE,
	@intermed_bank_name varchar(100),
	@extra_info varchar(255),
	@swift_text varchar(4000),
	@ref_num varchar(32),
	@address_lat varchar(100), 
	@cor_bank_code TINTBANKCODE, 
	@cor_bank_name varchar(100),
	@sender_tax_code varchar(11),
	@receiver_tax_code varchar(11),
	@det_of_charg char(3),
	@extra_info_descrip bit
SELECT 
	@op_num = OP_NUM,
	@doc_date = DOC_DATE,
	@doc_date_in_doc = DOC_DATE_IN_DOC,
	@iso = ISO,
	@amount = AMOUNT,
	@doc_num = DOC_NUM,
	@op_code = OP_CODE,
	@doc_type = 104,--DOC_TYPE, 
	@credit_id = CREDIT_ID,
	@credit = CREDIT,
	@bnk_cli_id = BNK_CLI_ID,
	@descrip = DESCRIP,
	@owner = OWNER,
	@account_extra = ACCOUNT_EXTRA,
	@prod_id = PROD_ID,
	@foreign_id = FOREIGN_ID,
	@channel_id = CHANNEL_ID,
	@dept_no = DEPT_NO,

	@sender_bank_code = SENDER_BANK_CODE,
	@sender_acc = SENDER_ACC,
	@receiver_bank_code = RECEIVER_BANK_CODE,
	@receiver_acc = RECEIVER_ACC,
	@sender_bank_name = SENDER_BANK_NAME,
	@receiver_bank_name = RECEIVER_BANK_NAME,
	@sender_acc_name = SENDER_ACC_NAME,
	@receiver_acc_name = RECEIVER_ACC_NAME,
	@intermed_bank_code = INTERMED_BANK_CODE,
	@intermed_bank_name = INTERMED_BANK_NAME,
	@extra_info = EXTRA_INFO,
	@swift_text = SWIFT_TEXT,
	@ref_num = REF_NUM,
	@cor_bank_code = COR_BANK_CODE, 
	@cor_bank_name = COR_BANK_NAME,
	@sender_tax_code = SENDER_TAX_CODE,
	@receiver_tax_code = RECEIVER_TAX_CODE,
	@det_of_charg = DET_OF_CHARG,
	@extra_info_descrip = EXTRA_INFO_DESCRIP
FROM dbo.DOCS_VALPLAT (NOLOCK)
WHERE OP_NUM = @rec_id

DECLARE @internal_transaction bit
SET @internal_transaction = 0
IF @@TRANCOUNT = 0
BEGIN
	BEGIN TRAN
	SET @internal_transaction = 1
END

DECLARE 
	@r int,
	@rec_id_2 int,
	@rec_state tinyint, 
	@dept_no_2 int,
	@swift_day_in_day int,
	@doc_date2 smalldatetime

EXEC dbo.GET_SETTING_INT 'SWIFT_DAY_IN_DAY', @swift_day_in_day OUTPUT

IF @new_rec_state >= 20 and @old_rec_state < 20
BEGIN
    SELECT @dept_no_2 = DEPT_NO
	FROM dbo.DEPTS (NOLOCK)
	WHERE BIC = @receiver_bank_code

	SET @debit_id = dbo.acc_get_acc_id(@dept_no_2, @receiver_acc, @iso)

	IF @swift_day_in_day = 0
	BEGIN
		IF @doc_date_in_doc <= @doc_date  
		BEGIN
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_2 OUTPUT,
				@user_id = 6, --Changed By Temo Mindorashvili&Dokho  @user_id,
				@owner = @owner,
				@doc_date = @doc_date,
				@doc_date_in_doc = @doc_date_in_doc,
				@doc_type = 114,--@doc_type,
				@debit_id = @credit_id,
				@credit_id = @debit_id,
				@iso = @iso,
				@amount = @amount,
				@rec_state = 0,
				@descrip = @descrip,
				@op_code = @op_code,
				@channel_id = 610,
				@foreign_id = @foreign_id,
				@prod_id = @prod_id,
				@dept_no = @dept_no_2,
				@bnk_cli_id = @bnk_cli_id,
				@account_extra = @account_extra,
				@relation_id = @rec_id,

				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name,
				@intermed_bank_code = @intermed_bank_code,
				@intermed_bank_name = @intermed_bank_name,
				@extra_info = @extra_info,
				@swift_text = @swift_text,
				@ref_num = @ref_num,
				@address_lat = @address_lat, 
				@cor_bank_code = @cor_bank_code, 
				@cor_bank_name = @cor_bank_name,
				@sender_tax_code = @sender_tax_code,
				@receiver_tax_code = @receiver_tax_code,
				@det_of_charg = @det_of_charg,
				@extra_info_descrip = @extra_info_descrip,
				@flags = 0x000000C0 --0x00000080 | 0x00000040 ->არ შეიძლება დებეტის და თანხის შეცვლა
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

				UPDATE dbo.OPS_0000
				SET PARENT_REC_ID = -2 -- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
				WHERE REC_ID = @rec_id 
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
		ELSE
		BEGIN
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_2 OUTPUT,
				@user_id = 6, --Changed By Temo Mindorashvili&Dokho  @user_id,
				@owner = @owner,
				@doc_date = @doc_date_in_doc,
				@doc_date_in_doc = @doc_date_in_doc,
				@doc_type = 114,--@doc_type,
				@debit_id = @credit_id,
				@credit_id = @debit_id,
				@iso = @iso,
				@amount = @amount,
				@rec_state = 0,
				@descrip = @descrip,
				@op_code = @op_code,
				@channel_id = 611,
				@foreign_id = @foreign_id,
				@prod_id = @prod_id,
				@dept_no = @dept_no_2,
				@bnk_cli_id = @bnk_cli_id,
				@account_extra = @account_extra,
				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name,
				@intermed_bank_code = @intermed_bank_code,
				@intermed_bank_name = @intermed_bank_name,
				@extra_info = @extra_info,
				@swift_text = @swift_text,
				@ref_num = @ref_num,
				@address_lat = @address_lat, 
				@cor_bank_code = @cor_bank_code, 
				@cor_bank_name = @cor_bank_name,
				@sender_tax_code = @sender_tax_code,
				@receiver_tax_code = @receiver_tax_code,
				@det_of_charg = @det_of_charg,
				@extra_info_descrip = @extra_info_descrip,
				@flags = 0x000000C0 --0x00000080 | 0x00000040 ->არ შეიძლება დებეტის და თანხის შეცვლა
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	END
	ELSE
	BEGIN
		SET @doc_date2 = convert(smalldatetime, @foreign_id)
		
		IF @doc_date_in_doc = @doc_date2
		BEGIN
			SET @credit_id = dbo.acc_get_acc_id(@dept_no, 361804002, @iso)
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_2 OUTPUT,
				@user_id = 6, --Changed By Temo Mindorashvili&Dokho  @user_id,
				@owner = @owner,
				@doc_date = @doc_date2,
				@doc_date_in_doc = @doc_date_in_doc,
				@doc_type = 114,--@doc_type,
				@debit_id = @credit_id,
				@credit_id = @debit_id,
				@iso = @iso,
				@amount = @amount,
				@rec_state = 0,
				@descrip = @descrip,
				@op_code = @op_code,
				@channel_id = 610,
				@foreign_id = @foreign_id,
				@prod_id = @prod_id,
				@dept_no = @dept_no_2,
				@bnk_cli_id = @bnk_cli_id,
				@account_extra = @account_extra,
				@relation_id = @rec_id,

				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name,
				@intermed_bank_code = @intermed_bank_code,
				@intermed_bank_name = @intermed_bank_name,
				@extra_info = @extra_info,
				@swift_text = @swift_text,
				@ref_num = @ref_num,
				@address_lat = @address_lat, 
				@cor_bank_code = @cor_bank_code, 
				@cor_bank_name = @cor_bank_name,
				@sender_tax_code = @sender_tax_code,
				@receiver_tax_code = @receiver_tax_code,
				@det_of_charg = @det_of_charg,
				@extra_info_descrip = @extra_info_descrip,
				@flags = 0x000000C0 --0x00000080 | 0x00000040 ->არ შეიძლება დებეტის და თანხის შეცვლა
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

				UPDATE dbo.OPS_0000
				SET PARENT_REC_ID = -2 -- -2: ყავს შვილი (იშლება ერთად, ავტორიზდება ცალ-ცალკე)
				WHERE REC_ID = @rec_id 
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END

		IF @doc_date_in_doc > @doc_date2
		BEGIN
			SET @credit_id = dbo.acc_get_acc_id(@dept_no, 361804000, @iso)
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_2 OUTPUT,
				@user_id = 6, --Changed By Temo Mindorashvili&Dokho  @user_id,
				@owner = @owner,
				@doc_date = @doc_date_in_doc,
				@doc_date_in_doc = @doc_date_in_doc,
				@doc_type = 114,--@doc_type,
				@debit_id = @credit_id,
				@credit_id = @debit_id,
				@iso = @iso,
				@amount = @amount,
				@rec_state = 0,
				@descrip = @descrip,
				@op_code = @op_code,
				@channel_id = 610,
				@foreign_id = @foreign_id,
				@prod_id = @prod_id,
				@dept_no = @dept_no_2,
				@bnk_cli_id = @bnk_cli_id,
				@account_extra = @account_extra,
				@relation_id = @rec_id,

				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name,
				@intermed_bank_code = @intermed_bank_code,
				@intermed_bank_name = @intermed_bank_name,
				@extra_info = @extra_info,
				@swift_text = @swift_text,
				@ref_num = @ref_num,
				@address_lat = @address_lat, 
				@cor_bank_code = @cor_bank_code, 
				@cor_bank_name = @cor_bank_name,
				@sender_tax_code = @sender_tax_code,
				@receiver_tax_code = @receiver_tax_code,
				@det_of_charg = @det_of_charg,
				@extra_info_descrip = @extra_info_descrip,
				@flags = 0x000000C0 --0x00000080 | 0x00000040 ->არ შეიძლება დებეტის და თანხის შეცვლა
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END

		IF @doc_date_in_doc < @doc_date2
		BEGIN
			SET @credit_id = dbo.acc_get_acc_id(@dept_no, 361804000, @iso)
			EXEC @r = dbo.ADD_DOC4
				@rec_id = @rec_id_2 OUTPUT,
				@user_id = 6, --Changed By Temo Mindorashvili&Dokho  @user_id,
				@owner = @owner,
				@doc_date = @doc_date2,
				@doc_date_in_doc = @doc_date_in_doc,
				@doc_type = 114,--@doc_type,
				@debit_id = @credit_id,
				@credit_id = @debit_id,
				@iso = @iso,
				@amount = @amount,
				@rec_state = 0,
				@descrip = @descrip,
				@op_code = @op_code,
				@channel_id = 610,
				@foreign_id = @foreign_id,
				@prod_id = @prod_id,
				@dept_no = @dept_no_2,
				@bnk_cli_id = @bnk_cli_id,
				@account_extra = @account_extra,
				@relation_id = @rec_id,

				@sender_bank_code = @sender_bank_code,
				@sender_acc = @sender_acc,
				@receiver_bank_code = @receiver_bank_code,
				@receiver_acc = @receiver_acc,
				@sender_bank_name = @sender_bank_name,
				@receiver_bank_name = @receiver_bank_name,
				@sender_acc_name = @sender_acc_name,
				@receiver_acc_name = @receiver_acc_name,
				@intermed_bank_code = @intermed_bank_code,
				@intermed_bank_name = @intermed_bank_name,
				@extra_info = @extra_info,
				@swift_text = @swift_text,
				@ref_num = @ref_num,
				@address_lat = @address_lat, 
				@cor_bank_code = @cor_bank_code, 
				@cor_bank_name = @cor_bank_name,
				@sender_tax_code = @sender_tax_code,
				@receiver_tax_code = @receiver_tax_code,
				@det_of_charg = @det_of_charg,
				@extra_info_descrip = @extra_info_descrip,
				@flags = 0x000000C0 --0x00000080 | 0x00000040 ->არ შეიძლება დებეტის და თანხის შეცვლა
				IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
		END
	END
END

IF @new_rec_state < 20 and @old_rec_state >= 20
BEGIN
	SELECT @rec_id_2 = REC_ID, @rec_state = REC_STATE
	FROM dbo.OPS_0000 (NOLOCK)
	WHERE RELATION_ID = @rec_id
			
	IF @rec_id_2 IS NOT NULL 
	BEGIN

		IF @rec_state >= 20
		BEGIN
			RAISERROR('ÃÀÌÏÊÉÃÄÁÖËÉ ÓÀÂÀÃÀÓÀáÀÃÏ ÃÀÅÀËÄÁÀ ÀÅÔÏÒÉÆÉÒÄÁÖËÉÀ!', 16, 1)
			IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK 
			RETURN 1
		END

		UPDATE dbo.OPS_0000
		SET PARENT_REC_ID = 0, UID = UID + 1
		WHERE REC_ID = @rec_id

		IF @@ERROR <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END

		EXEC @r = dbo.DELETE_DOC @rec_id = @rec_id_2, @user_id = @user_id, @dont_check_up = 1
		IF @@ERROR <> 0 OR @r <> 0 BEGIN IF @internal_transaction=1 AND @@TRANCOUNT>0 ROLLBACK RETURN 1 END
	END
END

IF @internal_transaction=1 AND @@TRANCOUNT>0 
	COMMIT TRAN
RETURN (0)
GO
