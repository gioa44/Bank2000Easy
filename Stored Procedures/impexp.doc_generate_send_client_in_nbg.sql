SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[doc_generate_send_client_in_nbg]
	@date smalldatetime,
	@por int,
	@row_id int,
	@uid int,
	@send_date smalldatetime,
	@new_descrip varchar(150),
	@user_id int
AS

SET NOCOUNT ON;


DECLARE 
	@debit TACCOUNT,
	@debit_id int,
	@head_branch_id int,
	@error_msg varchar(200)

EXEC dbo.GET_SETTING_ACC 'TRANSIT_ACC_DEBIT', @debit OUTPUT
IF ISNULL(@debit, 0) = 0
BEGIN
	RAISERROR ('ÐÀÒÀÌÄÔÒÉ "ÓÀÔÒÀÍÆÉÔÏ ÀÍÂÀÒÉÛÉ, ÒÏÌËÉÃÀÍÀÝ ÌÏáÃÄÁÀ ÂÀÖÒÊÅÄÅÄËÉ ÈÀÍáÄÁÉÓ ÖÊÀÍ ÃÀÁÒÖÍÄÁÀ" ÀÒ ÀÒÉÓ ÌÉÈÉÈÄÁÖËÉ ÓÉÓÔÄÌÉÓ ÊÏÍ×ÉÂÖÒÀÝÉÀÛÉ.', 16, 1)	
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
FROM impexp.DOCS_IN_NBG (UPDLOCK)
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id

IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

IF @uid <> @old_uid
BEGIN
	ROLLBACK 
	RAISERROR ('ÓÀÁÖÈÉ ÛÄÝÅËÉËÉÀ ÓáÅÀ ÌÏÌáÌÀÒÄÁËÉÓ ÌÉÄÒ',16,1)
	RETURN 1
END


DECLARE 
	@doc_type smallint,
	@rec_state tinyint,
	@op_code varchar(5),
	@flags int,
	@dept_no int,
	@ref_num varchar(32)

SET @doc_type = 104
SET @rec_state = 20
SET @op_code = 'NBG'
SET @flags = 6
SET @dept_no = @head_branch_id
SET @ref_num = null

IF ISNULL(RTRIM(LTRIM(@new_descrip)), '') = ''
	SET @new_descrip = @gd

EXEC @r = dbo.ADD_DOC4
   @rec_id = @finalyze_doc_rec_id OUTPUT
  ,@user_id = 6
  ,@owner = @user_id
  ,@doc_type = @doc_type 
  ,@doc_date = @send_date
  ,@doc_date_in_doc = @bdate
  ,@debit_id = @debit_id
  ,@credit_id = @acc_id
  ,@iso = 'GEL'
  ,@amount = @sum
  ,@rec_state = @rec_state
  ,@descrip = @new_descrip
  ,@op_code = @op_code
  ,@flags = @flags
  ,@doc_num = @ndoc
  ,@dept_no = @dept_no 
  
  ,@sender_bank_code = @nfa
  ,@sender_bank_name = @gb
  ,@sender_acc = @nls_ax
  ,@sender_acc_name = @g_o
  ,@sender_tax_code = @gik

  ,@receiver_bank_code = @nfb
  ,@receiver_bank_name = @mb
  ,@receiver_acc = @nlsk_ax
  ,@receiver_acc_name = @m_o
  ,@receiver_tax_code = @mik

  ,@ref_num = @ref_num
  ,@extra_info = @daminf
  ,@rec_date = @rec_date
  ,@saxazkod = @saxazkod
  ,@check_saldo = 0
  ,@add_tariff = 0
  ,@info = 0
  ,@channel_id = 500
  ,@relation_id = @doc_rec_id -- ÃÀÅÉÌÀáÓÏÅÒÏÈ, ÈÖ ÒÏÌÄËÌÀ ÓÀÁÖÈÌÀ ÂÀÌÏÉßÅÉÀ ÄÓ

IF @@ERROR <> 0 OR @r <> 0 BEGIN ROLLBACK RETURN 1 END

DECLARE @tbl TABLE (REC_ID int NOT NULL, [USER_ID] int NOT NULL, DATE_TIME smalldatetime NOT NULL, CHANGE_TYPE int NOT NULL, DESCRIP varchar(255))

INSERT INTO @tbl (REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT REC_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM impexp.DOCS_IN_NBG_CHANGES
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

UPDATE impexp.DOCS_IN_NBG
SET FINALYZE_DOC_REC_ID = @finalyze_doc_rec_id, UID = UID + 1
WHERE PORTION_DATE = @date AND PORTION = @por AND ROW_ID = @row_id
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP)
SELECT @date, @por, @row_id, [USER_ID], DATE_TIME, CHANGE_TYPE, DESCRIP
FROM @tbl
ORDER BY REC_ID
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

INSERT INTO impexp.DOCS_IN_NBG_CHANGES (PORTION_DATE, PORTION, ROW_ID, [USER_ID], CHANGE_TYPE, DESCRIP)
VALUES (@date, @por, @row_id, @user_id, 100, 'ÊËÉÄÍÔÉÀ ÀÍÂÀÒÉÛÆÄ ÃÀÓÌÉÓ ÓÀÁÖÈÉÓ ÂÄÍÄÒÀÝÉÀ')
IF @@ERROR <> 0 BEGIN ROLLBACK RETURN 1 END

COMMIT
RETURN @@ERROR
GO
