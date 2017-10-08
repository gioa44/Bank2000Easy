SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[loan_rep_portfolio2] (
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = NULL,
	@view_name sysname = 'dbo.LOAN_VW_LOAN_REPS',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@first_date smalldatetime,
	@last_date smalldatetime)
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
	@join_sql = @join_sql

----ÊÏÍÊÒÄÔÖËÉ ÓÄÓáÉÓÈÅÉÓ ÂÉÒÀÏÓ ÌÏÍÀÝÄÌÄÁÉÓ, ÂÀÝÄÌÖËÉ ÃÀ ÃÀ×ÀÒÖËÉ ÈÀÍáÉÓ
----ÜÀßÄÒÀ ÃÒÏÄÁÉÈ #tbl1 ÝáÒÉËÛÉ
----CURSOR-ÉÓ ÓÀÛÖÀËÄÁÉÈ
CREATE TABLE #tbl1 (LOAN_ID INT NOT NULL, 
					DESCRIP varchar(100) NOT NULL, 
					AMOUNT money NOT NULL, 
					DISBURSED money NOT NULL, 
					INPAYMENTED money NOT NULL, 
					PROLONGATION int NOT NULL, 
					PROLONGATION_DATE_1 smalldatetime NULL, 
					PROLONGATION_DATE_2 smalldatetime NULL,
					OVERDUE_DATE smalldatetime NULL,
					OVERDUE_PRINCIPAL money NULL, 
					OVERDUE_PRINCIPAL_INTEREST money NULL,
                    OVERDUE_PRINCIPAL_PENALTY money NULL, 
					OVERDUE_PERCENT money NULL,
                    OVERDUE_PERCENT_PENALTY	money NULL,
					CATEGORY_1 money NULL, 
					CATEGORY_2 money NULL, 
					CATEGORY_3 money NULL, 
					CATEGORY_4 money NULL, 
					CATEGORY_5 money NULL)

DECLARE cc CURSOR LOCAL FAST_FORWARD
FOR
SELECT LOAN_ID
FROM #tbl

DECLARE @loan_id int
OPEN cc
FETCH NEXT FROM cc INTO @loan_id

WHILE @@FETCH_STATUS = 0
BEGIN
	INSERT INTO #tbl1
	(LOAN_ID, DESCRIP, AMOUNT, DISBURSED, INPAYMENTED, PROLONGATION, PROLONGATION_DATE_1, PROLONGATION_DATE_2,
	 OVERDUE_DATE, OVERDUE_PRINCIPAL_INTEREST, OVERDUE_PRINCIPAL_PENALTY, OVERDUE_PERCENT, OVERDUE_PERCENT_PENALTY,
	 CATEGORY_1, CATEGORY_2, CATEGORY_3, CATEGORY_4, CATEGORY_5)

	SELECT LCD.LOAN_ID, LCD.DESCRIP, LCD.AMOUNT, 
		   ISNULL((SELECT SUM(LO1.AMOUNT) FROM dbo.LOAN_OPS LO1 WHERE LO1.OP_DATE BETWEEN @first_date AND @last_date AND LO1.OP_STATE = 255 AND LO1.OP_TYPE IN (dbo.loan_const_op_disburse(), dbo.loan_const_op_disburse_transh()) AND LO1.LOAN_ID = LCD.LOAN_ID), 0 ),
		   ISNULL((SELECT SUM(LO2.AMOUNT) FROM dbo.LOAN_OPS LO2 WHERE LO2.OP_DATE BETWEEN @first_date AND @last_date AND LO2.OP_STATE = 255 AND LO2.OP_TYPE = dbo.loan_const_op_payment() AND LO2.LOAN_ID = LCD.LOAN_ID), 0 ),
           LPD.PROLONGATION, LPD.PROLONGATION_DATE_1, LPD.PROLONGATION_DATE_2,
		   LDD.OVERDUE_PRINCIPAL, LDD.OVERDUE_PRINCIPAL_INTEREST, LDD.OVERDUE_PRINCIPAL_PENALTY, 
		   LDD.OVERDUE_PERCENT, LDD.OVERDUE_PERCENT_PENALTY,
		   LDD.CATEGORY_1, LDD.CATEGORY_2, LDD.CATEGORY_3, LDD.CATEGORY_4, LDD.CATEGORY_5
	FROM dbo.loan_get_loan_collateral_data(@loan_id) LCD
		INNER JOIN dbo.loan_get_loan_prolongation_data(@loan_id, @first_date, @last_date) LPD ON LPD.LOAN_ID = LCD.LOAN_ID
		INNER JOIN dbo.loan_get_loan_detail_data(@loan_id, @last_date) LDD ON LDD.LOAN_ID = LCD.LOAN_ID

	FETCH NEXT FROM cc INTO @loan_id
END
CLOSE cc
DEALLOCATE cc

----ÞÉÒÉÈÀÃÉ ÌÏÍÀÝÄÌÄÁÉÓ ßÀÌÏÙÄÁÀ
DECLARE @sql nvarchar(4000)

IF @field_list IS NULL OR @field_list = '*'
	SET @field_list = 'L.*'

SET @sql = N'
SELECT ' + @field_list + N', R.OVERDUE_DATE, R.OVERDUE_PRINCIPAL, R.OVERDUE_PRINCIPAL_INTEREST, R.OVERDUE_PRINCIPAL_PENALTY,
							 R.OVERDUE_PERCENT, R.OVERDUE_PERCENT_PENALTY, 
							 R.DESCRIP AS COLLATERAL_DESCRIP, R.AMOUNT AS COLLATERAL_AMOUNT,

							 ROUND(R.CATEGORY_1/100*L.RISK_PERC_RATE_1,2) AS RISK_CATEGORY_1_BALANCE,
							 ROUND(R.CATEGORY_2/100*L.RISK_PERC_RATE_2,2) AS RISK_CATEGORY_2_BALANCE,
							 ROUND(R.CATEGORY_3/100*L.RISK_PERC_RATE_3,2) AS RISK_CATEGORY_3_BALANCE,
							 ROUND(R.CATEGORY_4/100*L.RISK_PERC_RATE_4,2) AS RISK_CATEGORY_4_BALANCE,
							 ROUND(R.CATEGORY_5/100*L.RISK_PERC_RATE_5,2) AS RISK_CATEGORY_5_BALANCE,

							 R.DISBURSED, R.INPAYMENTED, 
							 R.PROLONGATION AS PROLONGATION, 
							 R.PROLONGATION_DATE_1, R.PROLONGATION_DATE_2
FROM ' + @view_name + N' L
	INNER JOIN #tbl1 R ON R.LOAN_ID = L.LOAN_ID'

EXEC sp_executesql @sql
DROP TABLE #tbl
DROP TABLE #tbl1

GO
