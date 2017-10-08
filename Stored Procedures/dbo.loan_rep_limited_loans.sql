SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[loan_rep_limited_loans] (
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = NULL,
	@view_name sysname = 'dbo.LOAN_VW_LOANS',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@distinct bit = 0)
AS

SET NOCOUNT ON;

DECLARE 
	@outer_limit_amount money,
	@outer_limit_iso TISO,
	@outer_limit_equ money,
	@today smalldatetime

SET @today = convert(smalldatetime,floor(convert(real,getdate())))

SET @outer_limit_amount = $1000000
SET @outer_limit_iso = 'EUR'

SET @outer_limit_equ = dbo.get_equ(@outer_limit_amount, @outer_limit_iso, @today)


IF ISNULL(@where_sql1, '') <> ''
	SET @where_sql3 = @where_sql3 + ' AND L.STATE <> 255'
ELSE
	SET @where_sql3 = @where_sql3 + 'L.STATE <> 255'
	
CREATE TABLE #tbl (LOAN_ID INT PRIMARY KEY, AMOUNT money NOT NULL, ISO char(3) NOT NULL, GROUP_ID int NULL, CLIENT_NO int NOT NULL)

INSERT INTO #tbl
EXEC [dbo].[loan_show_loans]
	@user_id = @user_id,
	@right_name = @right_name,
	@field_list = 'L.LOAN_ID, L.AMOUNT, L.ISO, L.GROUP_ID, L.CLIENT_NO',
	@view_name = 'dbo.LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql,
	@distinct = @distinct

DECLARE @sql nvarchar(4000)

IF @field_list IS NULL OR @field_list = '*'
	SET @field_list = 'L.*'

DECLARE @tbl2 TABLE (LOAN_ID INT NOT NULL, 
	VIOLATES_INT_CLIENT_LIMITS int NOT NULL, VIOLATES_INT_GROUP_LIMITS int NOT NULL,
	VIOLATES_EXT_CLIENT_LIMITS int NOT NULL, VIOLATES_EXT_GROUP_LIMITS int NOT NULL)

-- Groups

DECLARE @groups TABLE (GROUP_ID int NOT NULL PRIMARY KEY)

INSERT INTO @groups
SELECT G.GROUP_ID
FROM dbo.LOAN_GROUPS G
	INNER JOIN #tbl L ON L.GROUP_ID = G.GROUP_ID
GROUP BY G.GROUP_ID, G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO
HAVING SUM(dbo.get_equ(L.AMOUNT, L.ISO, @today)) > dbo.get_equ(G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO, @today)

INSERT INTO @tbl2
SELECT L.LOAN_ID, 0, 1, 0, 0
FROM #tbl L
	INNER JOIN @groups LG ON LG.GROUP_ID = L.GROUP_ID

DELETE FROM @groups

INSERT INTO @groups
SELECT G.GROUP_ID
FROM dbo.LOAN_GROUPS G
	INNER JOIN #tbl L ON L.GROUP_ID = G.GROUP_ID
GROUP BY G.GROUP_ID, G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO
HAVING SUM(dbo.get_equ(L.AMOUNT, L.ISO, @today)) > @outer_limit_equ

INSERT INTO @tbl2
SELECT L.LOAN_ID, 0, 0, 0, 1
FROM #tbl L
	INNER JOIN @groups LG ON LG.GROUP_ID = L.GROUP_ID


-- Clients

DECLARE @clients TABLE (CLIENT_NO int NOT NULL PRIMARY KEY)

INSERT INTO @clients
SELECT G.CLIENT_NO
FROM dbo.CLIENTS G
	INNER JOIN #tbl L ON L.CLIENT_NO = G.CLIENT_NO
GROUP BY G.CLIENT_NO, G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO
HAVING SUM(dbo.get_equ(L.AMOUNT, L.ISO, @today)) > dbo.get_equ(G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO, @today)

INSERT INTO @tbl2
SELECT L.LOAN_ID, 1, 0, 0, 0
FROM #tbl L
	INNER JOIN @clients C ON C.CLIENT_NO = L.CLIENT_NO

DELETE FROM @clients

INSERT INTO @clients
SELECT G.CLIENT_NO
FROM dbo.CLIENTS G
	INNER JOIN #tbl L ON L.CLIENT_NO = G.CLIENT_NO
GROUP BY G.CLIENT_NO, G.LOAN_LIMIT_AMOUNT, G.LOAN_LIMIT_ISO
HAVING SUM(dbo.get_equ(L.AMOUNT, L.ISO, @today)) > @outer_limit_equ

INSERT INTO @tbl2
SELECT L.LOAN_ID, 0, 0, 1, 0
FROM #tbl L
	INNER JOIN @clients C ON C.CLIENT_NO = L.CLIENT_NO

----


DROP TABLE #tbl

CREATE TABLE #tbl2 (LOAN_ID INT NOT NULL, 
	VIOLATES_INT_CLIENT_LIMITS bit NOT NULL, VIOLATES_INT_GROUP_LIMITS bit NOT NULL,
	VIOLATES_EXT_CLIENT_LIMITS bit NOT NULL, VIOLATES_EXT_GROUP_LIMITS bit NOT NULL)

INSERT INTO #tbl2 
SELECT LOAN_ID, SUM(VIOLATES_INT_CLIENT_LIMITS), SUM(VIOLATES_INT_GROUP_LIMITS), SUM(VIOLATES_EXT_CLIENT_LIMITS), SUM(VIOLATES_EXT_GROUP_LIMITS)
FROM @tbl2
GROUP BY LOAN_ID

SET @sql = N'
SELECT ' + @field_list + N',R.VIOLATES_INT_CLIENT_LIMITS, R.VIOLATES_INT_GROUP_LIMITS,R.VIOLATES_EXT_CLIENT_LIMITS, 
R.VIOLATES_EXT_GROUP_LIMITS, dbo.LOAN_FN_GET_CLIENT_RATING_HISTORY(L.CLIENT_NO, dbo.loan_open_date()) AS RAITING
FROM ' + @view_name + N' L
	INNER JOIN #tbl2 R ON R.LOAN_ID = L.LOAN_ID'

EXEC sp_executesql @sql

DROP TABLE #tbl2

GO
