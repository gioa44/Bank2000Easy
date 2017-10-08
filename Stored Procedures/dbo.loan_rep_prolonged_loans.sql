SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[loan_rep_prolonged_loans] (
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = NULL,
	@view_name sysname = 'dbo.LOAN_VW_LOAN_REPS',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@date smalldatetime,
	@distinct bit = 0)
AS
SET NOCOUNT ON;

CREATE TABLE #tbl (LOAN_ID INT PRIMARY KEY)

INSERT INTO #tbl
EXEC [dbo].[loan_show_loans]
	@user_id = @user_id,
	@right_name = @right_name,
	@field_list = 'L.LOAN_ID',
	@view_name = 'dbo.LOANS',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql,
	@distinct = @distinct

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT LOAN_ID
FROM #tbl

DECLARE @loan_id int

OPEN cc
FETCH NEXT FROM cc INTO @loan_id

CREATE TABLE #tbl1 (LOAN_ID INT NOT NULL, 
					PROLONGED INT NULL,
					RAITING varchar(3) NULL) 

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #tbl1
	SELECT LD.LOAN_ID, LD.PROLONGED, LD.RAITING 
	FROM dbo.loan_get_loan_data(@loan_id, @date) LD
	WHERE LD.PROLONGED > 0

	FETCH NEXT FROM cc INTO @loan_id
END

CLOSE cc
DEALLOCATE cc

DECLARE @sql nvarchar(4000)

IF @field_list IS NULL OR @field_list = '*'
	SET @field_list = 'L.*'

SET @sql = N'
SELECT ' + @field_list + N', R.PROLONGED AS PROLONGATION, R.RAITING, LO.OP_DATE
FROM ' + @view_name + N' L
	INNER JOIN #tbl1 R ON R.LOAN_ID = L.LOAN_ID	
	INNER JOIN LOAN_OPS LO ON LO.LOAN_ID = L.LOAN_ID
WHERE L.STATE <> 255 AND LO.OP_ID = (SELECT MAX(OP_ID)
									 FROM dbo.LOAN_OPS LO2 (NOLOCK) 
									 WHERE LO2.LOAN_ID = L.LOAN_ID 
									 AND LO2.OP_TYPE = dbo.loan_const_op_prolongation() 
									 AND LO2.OP_DATE <= @date)'

EXEC sp_executesql @sql, N'@date smalldatetime', @date
DROP TABLE #tbl
DROP TABLE #tbl1
GO
