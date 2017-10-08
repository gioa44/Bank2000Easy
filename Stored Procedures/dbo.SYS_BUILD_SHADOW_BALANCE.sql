SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[SYS_BUILD_SHADOW_BALANCE] 
	@end_date smalldatetime, 
	@iso TISO = '***',
	@equ bit = 1,
	@branch_str varchar(255) = '0',
	@shadow_level smallint = -1,
	@oob tinyint = 0
AS

DECLARE @dt smalldatetime
SET @dt = dbo.bank_open_date()

DECLARE
	@sql nvarchar(4000),
	@iso_where_str nvarchar(30),
	@oob_where_str nvarchar(30),
	@rec_state_str nvarchar(30),
	@where_str nvarchar(100)

SET @branch_str = ISNULL(@branch_str, '')

IF @iso = '***' /* Svodni */
	SET @iso_where_str = N''
ELSE 
IF @iso = '%%%' /* Valuta */
	SET @iso_where_str = N' AND ISO<>''GEL'''
ELSE 
	SET @iso_where_str = N' AND ISO=''' + @iso + N''''

IF @oob = 1
	SET @oob_where_str = N' AND DOC_TYPE < 200'
ELSE 
IF @oob = 2 
	SET @oob_where_str = N' AND DOC_TYPE >= 200'
ELSE
	SET @oob_where_str = N''

IF @shadow_level <= 0 
	SET @rec_state_str = ''  
ELSE 
IF @shadow_level = 1 
	SET @rec_state_str = ' AND REC_STATE>=10'
ELSE 
IF @shadow_level >= 2 
	SET @rec_state_str = ' AND REC_STATE>=20'

SET @where_str = @iso_where_str + @oob_where_str + @rec_state_str

DECLARE @accounts_details TABLE (ACC_ID int NOT NULL PRIMARY KEY, SALDO money)

DECLARE @saldos TABLE (ACC_ID int NOT NULL,DBO money,CRO money, SALDO money, PRIMARY KEY (ACC_ID))

INSERT INTO @accounts_details 
SELECT ACC_ID, SALDO
FROM dbo.ACCOUNTS_DETAILS 

DECLARE @tbl TABLE(
  DEPT_NO int NOT NULL,
  BAL_ACC decimal(6,2) NOT NULL,
  ISO char(3) collate database_default NOT NULL,
  [DBO] money NOT NULL,
  [CRO] money NOT NULL,
  [DBS] money NOT NULL,
  [CRS] money NOT NULL,
  RATE decimal(32,12) NOT NULL
  PRIMARY KEY CLUSTERED (DEPT_NO,BAL_ACC,ISO)
)

DECLARE @balances TABLE(
	DT smalldatetime NOT NULL,
	BRANCH_ID int NOT NULL,
	DEPT_NO int NOT NULL,
	BAL_ACC decimal(6,2) NOT NULL,
	ISO char(3) collate database_default NOT NULL,
	DBO money NOT NULL,
	DBO_EQU money NULL,
	CRO money NOT NULL,
	CRO_EQU money NULL,
	DBS money NOT NULL,
	DBS_EQU money NULL,
	CRS money NOT NULL,
	CRS_EQU money NULL,
	PRIMARY KEY (DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO)
)

INSERT INTO @balances (DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO, DBO_EQU, CRO, CRO_EQU, DBS, DBS_EQU, CRS, CRS_EQU)
SELECT DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO, DBO_EQU, CRO, CRO_EQU, DBS, DBS_EQU, CRS, CRS_EQU
FROM dbo.BALANCES_WIDE
WHERE DT = dbo.bank_open_date() - 1

CREATE TABLE #tblops (ACC_ID int NOT NULL PRIMARY KEY, DBO money NOT NULL, CRO money NOT NULL)

WHILE @dt <= @end_date
BEGIN

	SET @sql = N'INSERT INTO #tblops (ACC_ID, DBO, CRO)' + char(13) +
				N'SELECT H.ACC_ID, SUM(H.D), SUM(H.C)' + char(13) +
				N'FROM (' + char(13) +
				N'	SELECT DEBIT_ID AS ACC_ID, AMOUNT AS D, $0.0000 AS C FROM OPS_0000 (NOLOCK) WHERE DOC_DATE = @dt ' + @where_str + char(13) +
				N'	UNION ALL' + char(13) +
				N'	SELECT CREDIT_ID, $0.0000, AMOUNT FROM OPS_0000 (NOLOCK) WHERE DOC_DATE = @dt' + @where_str + N') H' + char(13) +
				N'	GROUP BY H.ACC_ID'

	EXEC sp_executesql @sql, N'@dt smalldatetime', @dt

	INSERT INTO @saldos (ACC_ID,DBO,CRO,SALDO)
	SELECT H.ACC_ID, ISNULL(H.DBO, $0.00), ISNULL(H.CRO, $0.00), ISNULL(A.SALDO, $0.00) + ISNULL(H.DBO, $0.00) - ISNULL(H.CRO, $0.00)
	FROM #tblops H
		INNER JOIN @accounts_details A ON A.ACC_ID = H.ACC_ID
 
	UPDATE @accounts_details 
	SET SALDO = ISNULL(A.SALDO, $0.00) + ISNULL(H.DBO, $.00) - ISNULL(H.CRO, $0.00)
	FROM @accounts_details A
	  INNER JOIN #tblops H ON A.ACC_ID = H.ACC_ID

	TRUNCATE TABLE #tblops

	INSERT INTO @tbl (DEPT_NO, BAL_ACC, ISO, DBO, CRO, DBS, CRS, RATE)
	SELECT A.DEPT_NO, A.BAL_ACC_ALT, A.ISO,
		SUM(ISNULL(R1.DBO, $0.00)), 
		SUM(ISNULL(R1.CRO, $0.00)), 
		SUM(CASE WHEN AD.SALDO > $0 THEN  AD.SALDO ELSE $0 END), 
		SUM(CASE WHEN AD.SALDO < $0 THEN -AD.SALDO ELSE $0 END), 
		1.0
	FROM dbo.ACCOUNTS A (NOLOCK) 
		LEFT JOIN @saldos R1 ON R1.ACC_ID = A.ACC_ID
		INNER JOIN @accounts_details AD ON AD.ACC_ID = A.ACC_ID
	WHERE R1.ACC_ID IS NOT NULL OR AD.SALDO <> $0
	GROUP BY A.DEPT_NO, A.BAL_ACC_ALT, A.ISO

	DELETE FROM @saldos

	IF @equ <> 0
	BEGIN
		DECLARE 
			@reval_bal_acc TBAL_ACC,
			@reval_offbal_acc TBAL_ACC

		SELECT @reval_bal_acc = VALS FROM dbo.INI_MONEY WHERE IDS = 'REVAL_BAL_ACC'
		SELECT @reval_offbal_acc = VALS FROM dbo.INI_MONEY WHERE IDS = 'REVAL_OFFBAL_ACC'

		IF @reval_bal_acc IS NULL
			SET @reval_bal_acc = 5902
		IF @reval_offbal_acc IS NULL
			SET @reval_offbal_acc = 999

		UPDATE A
		SET RATE = B.RATE
		FROM @tbl A
			INNER JOIN dbo.table_cross_rates_nbg ('GEL', @dt) B ON B.ISO = A.ISO
		WHERE A.ISO <> 'GEL'

		DECLARE @rate_diffs TABLE (
		  ISO char(3), 
		  RATE_DIFF decimal(32, 12), 
		  PRIMARY KEY CLUSTERED(ISO)
		)

		DECLARE @turn_diffs TABLE (
			DEPT_NO int NOT NULL, 
			BAL_ACC decimal(6,2) NOT NULL, 
			ISO char(3) collate database_default NOT NULL, 
			DBO money NOT NULL, 
			CRO money NOT NULL,
			PRIMARY KEY (DEPT_NO, BAL_ACC, ISO))

		DECLARE @turn_diffs2 TABLE (
			DEPT_NO int NOT NULL, 
			BAL_ACC decimal(6,2) NOT NULL, 
			ISO char(3) collate database_default NOT NULL, 
			DBO money NOT NULL, 
			CRO money NOT NULL,
			PRIMARY KEY (DEPT_NO, BAL_ACC, ISO))

		INSERT INTO @rate_diffs 
		SELECT * 
		FROM dbo.table_cross_rate_diffs_nbg (default, @dt)
		WHERE RATE_DIFF <> 0

		INSERT INTO @turn_diffs2
		SELECT B.DEPT_NO, B.BAL_ACC, B.ISO,
			ROUND(CASE WHEN R.RATE_DIFF > 0 THEN B.DBS * R.RATE_DIFF ELSE - B.CRS * R.RATE_DIFF END, 4) AS DBO,
			ROUND(CASE WHEN R.RATE_DIFF > 0 THEN B.CRS * R.RATE_DIFF ELSE - B.DBS * R.RATE_DIFF END, 4) AS CRO
		FROM @balances B
		  INNER JOIN @rate_diffs R ON R.ISO = B.ISO
		WHERE B.DT = @dt - 1 AND B.ISO <> 'GEL' AND (B.DBS <> $0 OR B.CRS <> $0)

		DELETE FROM @rate_diffs

		INSERT INTO @turn_diffs
		SELECT X.DEPT_NO, X.BAL_ACC, X.ISO, SUM(X.DBO), SUM(X.CRO)
		FROM 
		(
			SELECT * from @turn_diffs2

			UNION ALL

			SELECT C.DEPT_NO, @reval_bal_acc, C.ISO, C.DBO, $0.0000
			FROM (
				SELECT B.DEPT_NO, B.ISO, SUM(B.CRO) AS DBO
				FROM @turn_diffs2 B
				WHERE BAL_ACC >= 1000
				GROUP BY B.DEPT_NO, B.ISO
			) C	INNER JOIN dbo.DEPTS D ON D.DEPT_NO = C.DEPT_NO

			UNION ALL

			SELECT C.DEPT_NO, @reval_offbal_acc, C.ISO, C.DBO, $0.0000
			FROM (
				SELECT B.DEPT_NO, B.ISO, SUM(B.CRO) AS DBO
				FROM @turn_diffs2 B
				WHERE BAL_ACC < 1000
				GROUP BY B.DEPT_NO, B.ISO
			) C	

			UNION ALL

			SELECT C.DEPT_NO, @reval_bal_acc, C.ISO, $0.0000, C.CRO
			FROM (
				SELECT B.DEPT_NO, B.ISO, SUM(B.DBO) AS CRO
				FROM @turn_diffs2 B 
				WHERE BAL_ACC >= 1000
				GROUP BY B.DEPT_NO, B.ISO
			) C	INNER JOIN dbo.DEPTS D ON D.DEPT_NO = C.DEPT_NO

			UNION ALL

			SELECT C.DEPT_NO, @reval_offbal_acc, C.ISO, $0.0000, C.CRO
			FROM (
				SELECT B.DEPT_NO, B.ISO, SUM(B.DBO) AS CRO
				FROM @turn_diffs2 B 
				WHERE BAL_ACC < 1000
				GROUP BY B.DEPT_NO, B.ISO
			) C	

		) X
		GROUP BY X.DEPT_NO, X.BAL_ACC, X.ISO

		DELETE FROM @turn_diffs2

		INSERT INTO @tbl (DEPT_NO, BAL_ACC, ISO, DBO, CRO, DBS, CRS, RATE)
		SELECT A.DEPT_NO, A.BAL_ACC, A.ISO, $0.0000, $0.0000, $0.0000, $0.0000, 1.0
		FROM @turn_diffs A
		WHERE NOT EXISTS(SELECT * FROM @tbl B WHERE B.DEPT_NO = A.DEPT_NO AND B.BAL_ACC = A.BAL_ACC AND B.ISO = A.ISO)

		INSERT INTO @balances
		SELECT @dt, D.BRANCH_ID, A.DEPT_NO, A.BAL_ACC, A.ISO, 
			A.DBO, 
			ROUND(A.DBO * A.RATE, 4) + ISNULL(B.DBO, $0.0000),
			A.CRO, 
			ROUND(A.CRO * A.RATE, 4) + ISNULL(B.CRO, $0.0000), 
			A.DBS, 
			ROUND(A.DBS * A.RATE, 4), 
			A.CRS, 
			ROUND(A.CRS * A.RATE, 4)
		FROM @tbl A
			LEFT JOIN @turn_diffs B ON B.DEPT_NO = A.DEPT_NO AND B.BAL_ACC = A.BAL_ACC AND B.ISO = A.ISO
			INNER JOIN dbo.DEPTS D (NOLOCK) ON D.DEPT_NO = A.DEPT_NO

		DELETE FROM @turn_diffs
	END
	ELSE
	BEGIN
		INSERT INTO @balances
		SELECT @dt, D.BRANCH_ID, A.DEPT_NO, A.BAL_ACC, A.ISO, 
			A.DBO, 
			NULL,
			A.CRO, 
			NULL,
			A.DBS, 
			NULL,
			A.CRS, 
			NULL
		FROM @tbl A
			INNER JOIN dbo.DEPTS D (NOLOCK) ON D.DEPT_NO = A.DEPT_NO
	END

	DELETE FROM @tbl
		
	-- DELETE RECORDS FROM LAST CLOSED DAY
	IF @dt = dbo.bank_open_date()
		DELETE FROM @balances
		WHERE DT = @dt - 1

	SET @dt = @dt + 1
END

DROP TABLE #tblops

IF @equ <> 0
	INSERT INTO #shadow_balance (DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO, CRO, DBS, CRS)
	SELECT DT, BRANCH_ID, DEPT_NO, BAL_ACC,	ISO, DBO_EQU, CRO_EQU, DBS_EQU, CRS_EQU
	FROM @balances
ELSE
	INSERT INTO #shadow_balance (DT, BRANCH_ID, DEPT_NO, BAL_ACC, ISO, DBO, CRO, DBS, CRS)
	SELECT DT, BRANCH_ID, DEPT_NO, BAL_ACC,	ISO, DBO, CRO, DBS, CRS
	FROM @balances

GO
