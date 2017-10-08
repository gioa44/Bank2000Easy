SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [impexp].[generate_statement]
  @sw_rec_id int = null, 
  @acc_id int = null,
  @start_date smalldatetime  = null,
  @end_date smalldatetime = null,
  @user_id int = null,
  @show_subsums bit = 0
AS 
 
SET NOCOUNT ON


IF @sw_rec_id IS NULL
BEGIN
	IF @user_id IS NOT NULL
	BEGIN
		INSERT INTO dbo.B2000_LOG ([USER_ID],ACTION_CODE,DESCRIP,APP_SRV_ID) 
		VALUES (@user_id, 7, 'ÀÌÏÍÀßÄÒÉÓ ÂÄÍÄÒÀÝÉÀ. ÀÍÂ# ' + dbo.acc_get_branch_account_ccy(@acc_id), 1)
	END

	DECLARE @T TABLE (
		SW_REC_ID int,
		REC_ID int,
		DOC_TYPE smallint, 
		DT smalldatetime NOT NULL, 
		ACCOUNT decimal(15,0) NULL, 
		ACC_ID int, 
		DESCRIP varchar(150), 
		EXTRA_INFO varchar(150),
		DOC_NUM int,
		OP_CODE varchar(5),
		REC_STATE tinyint,
		PARENT_REC_ID int,
		ACCOUNT_EXTRA decimal(15,0) NULL,
		DOC_DATE_IN_DOC smalldatetime NULL, 
		IS_ARC bit, 
		DBO money, 
		DBO_EQU money, 
		CRO money, 
		CRO_EQU money, 
		SALDO money,
		SALDO_EQU money,
		SORT_ID int,
		SW_CODE char(3),
		SW_CODE_DESCRIP varchar(100) 
		PRIMARY KEY CLUSTERED (DT,REC_ID))

	INSERT INTO @T(SW_REC_ID, REC_ID, DOC_TYPE, DT, ACCOUNT, ACC_ID, DESCRIP, EXTRA_INFO, DOC_NUM, OP_CODE, REC_STATE, PARENT_REC_ID, ACCOUNT_EXTRA, DOC_DATE_IN_DOC, IS_ARC, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU, SORT_ID)
	SELECT 0, REC_ID, DOC_TYPE, DT, ACCOUNT, ACC_ID, DESCRIP, EXTRA_INFO, DOC_NUM, OP_CODE, REC_STATE, PARENT_REC_ID, ACCOUNT_EXTRA, DOC_DATE_IN_DOC, IS_ARC, DBO, DBO_EQU, CRO, CRO_EQU, SALDO, SALDO_EQU, SORT_ID
	FROM dbo.acc_show_statement(@acc_id, default, @start_date, @end_date, 20, 1, default)
	ORDER BY DT,REC_ID

	UPDATE @T
	SET DT = @start_date
	WHERE DT < @start_date 

	SELECT * FROM @T
	ORDER BY DT,REC_ID
END
ELSE
BEGIN
	SELECT * FROM impexp.STATEMENT_DETAILS (NOLOCK)
	WHERE SW_REC_ID = @sw_rec_id
	ORDER BY DT, REC_ID
END
GO
