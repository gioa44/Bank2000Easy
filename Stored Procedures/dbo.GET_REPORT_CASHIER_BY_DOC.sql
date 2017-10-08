SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[GET_REPORT_CASHIER_BY_DOC]
	@acc_id int,
	@min_doc_type tinyint,
	@start_date smalldatetime,
	@end_date smalldatetime,
	@user_id int,
	@shadow_level smallint = 1
AS

SET NOCOUNT ON

DECLARE 
	@rec_state tinyint

IF @shadow_level >= 0
	SET @rec_state = @shadow_level * 10

DECLARE @tbl TABLE (ACC_ID int, CLIENT_NAME varchar(150), DOC_NUM int, AMOUNT money, DOC_DATE smalldatetime, REC_ID int, IS_ARC bit, OWNER int)

IF @start_date < dbo.bank_open_date()
	INSERT INTO @tbl
	SELECT CASE WHEN D.DOC_TYPE BETWEEN 120 AND 129 THEN D.CREDIT_ID ELSE D.DEBIT_ID END,
		ISNULL(P.FIRST_NAME,'') + ' ' + ISNULL(P.LAST_NAME,''),
		D.DOC_NUM, D.AMOUNT, D.DOC_DATE, D.REC_ID, 1, D.OWNER 
	FROM dbo.OPS_ARC D (NOLOCK) 
		INNER JOIN dbo.OPS_HELPER_ARC H (NOLOCK) ON H.REC_ID = D.REC_ID
		LEFT JOIN dbo.DOC_DETAILS_ARC_PASSPORTS P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
	WHERE H.ACC_ID = @acc_id AND H.DT BETWEEN @start_date AND @end_date AND D.DOC_DATE BETWEEN @start_date AND @end_date AND
		D.CASHIER = @user_id AND D.DOC_TYPE BETWEEN @min_doc_type AND (@min_doc_type + 9)

IF @end_date >= dbo.bank_open_date() AND @shadow_level >=0 
	INSERT INTO @tbl
	SELECT CASE WHEN D.DOC_TYPE BETWEEN 120 AND 129 THEN D.CREDIT_ID ELSE D.DEBIT_ID END,
		ISNULL(P.FIRST_NAME,'') + ' ' + ISNULL(P.LAST_NAME,''),
		D.DOC_NUM, D.AMOUNT, D.DOC_DATE, D.REC_ID, 0, D.OWNER 
	FROM dbo.OPS_0000 D (NOLOCK) 
		INNER JOIN dbo.OPS_HELPER_0000 H (NOLOCK) ON H.REC_ID = D.REC_ID
		LEFT JOIN dbo.DOC_DETAILS_PASSPORTS P (NOLOCK) ON P.DOC_REC_ID = D.REC_ID
	WHERE H.ACC_ID = @acc_id AND H.DT BETWEEN @start_date AND @end_date AND D.DOC_DATE BETWEEN @start_date AND @end_date AND 
		D.CASHIER = @user_id AND D.DOC_TYPE BETWEEN @min_doc_type AND (@min_doc_type + 9)


SELECT T.DOC_NUM, T.DOC_DATE, A.ACCOUNT, T.AMOUNT, T.CLIENT_NAME, U.USER_FULL_NAME, T.REC_ID, T.IS_ARCFROM @tbl T
	INNER JOIN dbo.ACCOUNTS A (NOLOCK) ON A.ACC_ID = T.ACC_ID
	INNER JOIN dbo.USERS U (NOLOCK) ON U.[USER_ID] = T.OWNER
GO
