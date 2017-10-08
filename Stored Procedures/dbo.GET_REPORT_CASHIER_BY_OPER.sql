SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[GET_REPORT_CASHIER_BY_OPER]
	@acc_id int,
	@dt smalldatetime,
	@user_id int,
	@dd int
AS

SET NOCOUNT ON

DECLARE @tbl TABLE (REC_ID int, [USER_ID] int, AMOUNT money, AMOUNT2 money)

IF @dd = 130 -- გასავალი
BEGIN
	IF @dt < dbo.bank_open_date()
	BEGIN
		INSERT INTO @tbl
		SELECT D.REC_ID, D.OWNER, D.AMOUNT, $0 -- ÂÀÝÄÌÖËÉ ÊËÉÄÍÔÄÁÆÄ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID <> 1 AND D.DOC_TYPE BETWEEN 130 AND 149
		
		UNION ALL

		SELECT 0, -2, D.AMOUNT, $0				-- ÌÏËÀÒÄÄÁÆÄ ÂÀÃÀÝÄÌÖËÉ
		FROM dbo.OPS_ARC D
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 130 AND 149

		UNION ALL

		SELECT 0, -1, $0, D.AMOUNT				-- ÌÏËÀÒÄÄÁÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -9, $0, D.AMOUNT				-- ÐÒÏØÄÛÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 2 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -3, $0, D.AMOUNT				-- ÊËÉÄÍÔÄÁÉÓÀÂÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND NOT D.CHANNEL_ID IN (1, 2) AND D.DOC_TYPE BETWEEN 120 AND 129
	END
	ELSE
	BEGIN
		INSERT INTO @tbl
		SELECT D.REC_ID, D.OWNER, D.AMOUNT, $0	-- ÂÀÝÄÌÖËÉ ÊËÉÄÍÔÄÁÆÄ
		FROM dbo.OPS_0000 D
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID <> 1 AND D.DOC_TYPE BETWEEN 130 AND 149

		UNION ALL

		SELECT 0, -2, D.AMOUNT, $0				-- ÌÏËÀÒÄÄÁÆÄ ÂÀÃÀÝÄÌÖËÉ
		FROM dbo.OPS_0000 D
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 130 AND 149

		UNION ALL

		SELECT 0, -1, $0, D.AMOUNT				-- ÌÏËÀÒÄÄÁÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -9, $0, D.AMOUNT				-- ÐÒÏØÄÛÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 2 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -3, $0, D.AMOUNT				-- ÊËÉÄÍÔÄÁÉÓÀÂÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND NOT D.CHANNEL_ID IN (1, 2) AND D.DOC_TYPE BETWEEN 120 AND 129
	END
END
ELSE  -- შემოსავალი
BEGIN
	IF @dt < dbo.bank_open_date()
	BEGIN
		INSERT INTO @tbl
		SELECT D.REC_ID, D.OWNER, D.AMOUNT, $0	-- ÊËÉÄÍÔÄÁÉÓÀÂÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND NOT D.CHANNEL_ID IN (1, 2) AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -1, D.AMOUNT, $0				-- ÌÏËÀÒÄÄÁÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -9, D.AMOUNT, $0				-- ÐÒÏØÄÛÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 2 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -2, $0, D.AMOUNT				-- ÌÏËÀÒÄÄÁÆÄ ÂÀÃÀÝÄÌÖËÉ
		FROM dbo.OPS_ARC D
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 130 AND 149

		UNION ALL

		SELECT 0, -4, $0, D.AMOUNT				-- ÊËÉÄÍÔÄÁÆÄ ÂÀÝÄÌÖËÉ
		FROM dbo.OPS_ARC D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_ARC H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID <> 1 AND D.DOC_TYPE BETWEEN 130 AND 139
	END
	ELSE
	BEGIN
		INSERT INTO @tbl
		SELECT D.REC_ID, D.OWNER, D.AMOUNT, $0	-- ÊËÉÄÍÔÄÁÉÓÀÂÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND NOT D.CHANNEL_ID IN (1, 2) AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -1, D.AMOUNT, $0				-- ÌÏËÀÒÄÄÁÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -9, D.AMOUNT, $0				-- ÐÒÏØÄÛÉÃÀÍ ÛÄÌÏÓÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.DEBIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 2 AND D.DOC_TYPE BETWEEN 120 AND 129

		UNION ALL

		SELECT 0, -2, $0, D.AMOUNT				-- ÌÏËÀÒÄÄÁÆÄ ÂÀÃÀÝÄÌÖËÉ
		FROM dbo.OPS_0000 D
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID = 1 AND D.DOC_TYPE BETWEEN 130 AND 149

		UNION ALL

		SELECT 0, -4, $0, D.AMOUNT				-- ÊËÉÄÍÔÄÁÆÄ ÂÀÝÄÌÖËÉ
		FROM dbo.OPS_0000 D (NOLOCK)
			INNER JOIN dbo.OPS_HELPER_0000 H ON H.ACC_ID = D.CREDIT_ID AND H.DT = D.DOC_DATE AND H.REC_ID = D.REC_ID
		WHERE H.ACC_ID = @acc_id AND H.DT = @dt AND D.CASHIER = @user_id AND D.CHANNEL_ID <> 1 AND D.DOC_TYPE BETWEEN 130 AND 139
	END
END

SELECT A.[USER_ID], CASE A.[USER_ID] 
		WHEN -4 THEN 'ÊËÉÄÍÔÄÁÆÄ ÂÀÝÄÌÖËÉ' 
		WHEN -3 THEN 'ÊËÉÄÍÔÄÁÉÓÀÂÀÍ ÛÄÌÏÓÖËÉ' 
		WHEN -9  THEN 'ÐÒÏØÄÛÉÃÀÍ ÛÄÌÏÓÖËÉ' 
		WHEN -2 THEN 'ÌÏËÀÒÄÄÁÆÄ ÂÀÃÀÝÄÌÖËÉ' 
		WHEN -1  THEN 'ÌÏËÀÒÄÄÁÉÃÀÍ ÛÄÌÏÓÖËÉ' 
		ELSE U.USER_FULL_NAME END AS USER_FULL_NAME, 
		A.DOC_COUNT, A.AMOUNT, 
		A.DOC_COUNT2, A.AMOUNT2
FROM (
	SELECT T.[USER_ID], 
		SUM(CASE WHEN T.AMOUNT2 = $0 THEN 1 ELSE 0 END) AS DOC_COUNT, 
		SUM(CASE WHEN T.AMOUNT2 > $0 THEN 1 ELSE 0 END) AS DOC_COUNT2, 
		SUM(T.AMOUNT) AS AMOUNT, 
		SUM(T.AMOUNT2) AS AMOUNT2
	FROM @tbl T
	GROUP BY T.[USER_ID]) A
LEFT JOIN dbo.USERS U (NOLOCK) ON U.[USER_ID] = A.[USER_ID]
GO
