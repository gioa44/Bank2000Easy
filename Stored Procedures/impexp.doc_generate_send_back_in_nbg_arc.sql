SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_generate_send_back_in_nbg_arc]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@send_date smalldatetime,
	@user_id int
AS

SET NOCOUNT ON;

DECLARE 
	@head_branch_id int,
	@debit TACCOUNT,
	@debit_id int,
	@credit TACCOUNT,
	@credit_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'TRANSIT_ACC_DEBIT', @debit OUTPUT
IF ISNULL(@debit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÂÀÖÒÊÅÄÅÄËÉ ÈÀÍáÄÁÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

EXEC dbo.GET_SETTING_ACC 'CORR_ACC_NA', @credit OUTPUT
IF ISNULL(@credit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌÄËÆÄÝ ßÀÅÀ ÂÀÃÀÒÉÝáÅÄÁÉ ÓáÅÀ ÁÀÍÊÛÉ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

SET @head_branch_id = dbo.bank_head_branch_id()

SET @debit_id = dbo.acc_get_acc_id(@head_branch_id, @debit, 'GEL')

IF @debit_id IS NULL
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @debit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

SET @credit_id = dbo.acc_get_acc_id(@head_branch_id, @credit, 'GEL')

IF @credit_id IS NULL
BEGIN
	SET @error_msg = 'ÀÍÂÀÒÉÛÉ ' + CONVERT(varchar(10),@head_branch_id) + '/' + convert(varchar(20), @credit) + '/GEL' + ' ÀÒ ÌÏÉÞÄÁÍÀ'
	RAISERROR (@error_msg , 16, 1)
	IF @@TRANCOUNT > 0 ROLLBACK 
	RETURN 1
END

DECLARE 
	@ndoc int,
	@bdate smalldatetime,
	@nfa int,
	@gik varchar(11),
	@nls varchar(9),
	@sum money, 
	@nfb int,
	@mik varchar(11),
	@nlsk varchar(9),
	@gb varchar(50),
	@g_o varchar(100),
	@mb varchar(50),
	@m_o varchar(100),
	@gd varchar(200),
	@nls_ax varchar(34),
	@nlsk_ax varchar(34),
	@rec_date smalldatetime,
	@saxazkod varchar(9),
	@daminf varchar(250),
	@acc_id int,
	@doc_date smalldatetime,
	@doc_rec_id int,
	@finalyze_doc_rec_id int,
	@error_reason varchar(100),
	@old_uid int,
	@r int

BEGIN TRAN

SELECT 
	@doc_rec_id = DOC_REC_ID,
	@old_uid = UID,
	@doc_date = DOC_DATE,
	@ndoc = NDOC, 
	@bdate = DATE, 
	@nfa = NFA, 
	@gik = GIK, 
	@nls = NLS, 
	@sum = [SUM], 
	@nfb = NFB, 
	@mik = MIK, 
	@nlsk = NLSK, 
	@gb = GB, 
	@g_o = G_O, 
	@mb = MB, 
	@m_o = M_O, 
	@gd = GD, 
	@nls_ax = NLS_AX, 
	@nlsk_ax = NLSK_AX, 
	@rec_date = REC_DATE, 
	@saxazkod = SAXAZKOD, 
	@daminf = DAMINF,
	@error_reason = ERROR_REASON,
	@acc_id = ACC_ID
FROM impexp.DOCS_IN_NBG_ARC (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

IF @uid <> @old_uid
BEGIN
	ROLLBACK 
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END

DECLARE
	@bank_code varchar(9),
	@bank_name varchar(100),
	@bank_tax_code varchar(20)

SELECT @bank_code = CONVERT(varchar(9), DP.CODE9), @bank_name = B.DESCRIP
FROM dbo.DEPTS DP
	INNER JOIN dbo.BANKS B ON B.CODE9 = DP.CODE9
WHERE DP.DEPT_NO = @head_branch_id

--DECLARE @extra_info varchar(250)
--SET @extra_info = 'ÀÍÂÀÒÉÛÉ ÀÒ ÌÏÉÞÄÁÍÀ, ' + ISNULL(@nlsk_ax, '') + ' (' + ISNULL(@m_o, '') + ')'


EXEC dbo.GET_SETTING_STR 'BANK_TAX_CODE', @bank_tax_code OUTPUT

EXEC @r = dbo.ADD_DOC4
   @rec_id = @finalyze_doc_rec_id OUTPUT
  ,@user_id = 6
  ,@owner = @user_id
  ,@doc_type = 102
  ,@doc_date = @send_date
  ,@doc_date_in_doc = @send_date --@bdate
  ,@debit_id = @debit_id
  ,@credit_id = @credit_id
  ,@iso = 'GEL'
  ,@amount = @sum
  ,@rec_state = 10
  ,@descrip = 'ÀÒÀÓßÏÒÀÃ ÜÀÒÉÝáÖËÉ ÈÀÍáÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ'
  ,@op_code = 'NBG'
  ,@flags = 0x3C09E4
  ,@doc_num = @ndoc
  ,@dept_no = @head_branch_id
  
  ,@sender_bank_code = @bank_code
  ,@sender_bank_name = @bank_name
  ,@sender_acc = @debit
  ,@sender_acc_name = @bank_name
  ,@sender_tax_code = @bank_tax_code

  ,@receiver_bank_code = @nfa
  ,@receiver_bank_name = @gb
  ,@receiver_acc = @nls_ax
  ,@receiver_acc_name = @g_o
  ,@receiver_tax_code = @gik

  ,@ref_num = '' -- todo
  ,@extra_info = @error_reason
  ,@rec_date = @send_date
  ,@saxazkod = @saxazkod
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@info = 0
  ,@channel_id = 500
  ,@relation_id = @doc_rec_id -- ÃÀÅÉÌÀáÓÏÅÒÏÈ, ÈÖ ÒÏÌÄËÌÀ ÓÀÁÖÈÌÀ ÂÀÌÏÉßÅÉÀ ÄÓ

IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_NBG_ARC
SET FINALYZE_DOC_REC_ID = @finalyze_doc_rec_id, ACC_ID = NULL, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

--INSERT INTO impexp.DOCS_IN_NBG_ARC_CHANGES (PORTION_DATE, PORTION, ROW_ID, REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
--VALUES (@date, @por, @row_id, xxx, @user_id, 100, 'ÖÊÀÍ ÃÀÁÒÖÍÄÁÉÓ ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÀ')
--IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
