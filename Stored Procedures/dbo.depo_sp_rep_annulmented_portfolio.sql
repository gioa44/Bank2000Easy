SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_rep_annulmented_portfolio] (
	@user_id int,
	@right_name varchar(100) = 'ÍÀáÅÀ',
	@field_list varchar(1000) = 'D.DEPO_ID',
	@view_name sysname = 'dbo.DEPO_VW_DEPO_REP_LIST',
	@where_sql1 varchar(1000) = NULL,
	@where_sql2 varchar(1000) = NULL,
	@where_sql3 varchar(1000) = NULL,
	@join_sql varchar(1000) = NULL,
	@action_date smalldatetime, 
	@date smalldatetime)
AS
SET NOCOUNT ON;

CREATE TABLE #tbl (DEPO_ID INT PRIMARY KEY)

INSERT INTO #tbl
EXEC dbo.depo_show_depos2
	@user_id = @user_id,
	@right_name = @right_name,
	@field_list = 'D.DEPO_ID',
	@view_name = 'dbo.DEPO_VW_DEPO_REP_LIST',
	@where_sql1 = @where_sql1,
	@where_sql2 = @where_sql2,
	@where_sql3 = @where_sql3,
	@join_sql = @join_sql

DECLARE @sql nvarchar(4000)

IF @field_list IS NULL OR @field_list = '*'
	SET @field_list = 'D.*'

SET @sql = N'
SELECT ' + @field_list + N', D.STATE, D.DEPT_NO, D.ALIAS, D.DEPT_DESCRIP,
		D.CLIENT_NO, D.CLIENT_DESCRIP, D.IS_RESIDENT, D.IS_INSIDER, D.TAX_INSP_CODE,
		D.CLIENT_TYPE, D.CLIENT_TYPE_DESCRIP, D.CLIENT_SUBTYPE, D.CLIENT_SUBTYPE_DESCRIP, D.CLIENT_SUBTYPE2_DESCRIP, CA.ATTRIB_VALUE AS CLIENT_SEGMENT,		
		D.PROD_ID, D.PROD_CODE, D.PROD_NO, D.PROD_DESCRIP,
		D.AGREEMENT_NO, D.DEPO_ACC_ID, D.DEPO_ACCOUNT,	D.DEPO_ACCOUNT_BAL_ACC,	D.ISO, D.AMOUNT, dbo.get_equ(D.AMOUNT, D.ISO, @date) AS AMOUNT_EQU,
		D.INTRATE, dbo.depo_fn_rep_get_annulmen_interest(D.START_DATE, D.ANNULMENT_DATE, D.DAYS_IN_YEAR, D.AMOUNT, ISNULL(D.TOTAL_PAYED_AMOUNT, $0.00)) AS REAL_INTRATE,
		D.START_DATE, D.PERIOD_DAYS, dbo.date_month_between(D.START_DATE, D.END_DATE) AS PERIOD_MONTHS, D.ANNULMENT_DATE, D.END_DATE,
		dbo.depo_fn_rep_get_before_annul_realize_interest(D.DEPO_ID) AS ANNUL_REALIZE_INTEREST, dbo.get_equ(dbo.depo_fn_rep_get_before_annul_realize_interest(D.DEPO_ID), D.ISO, @date) AS ANNUL_REALIZE_INTEREST_EQU,
		dbo.depo_fn_rep_get_before_annul_tax_payed_amount(D.DEPO_ID) AS ANNUL_TAX_PAYED, dbo.depo_fn_rep_get_before_annul_tax_payed_amount_equ(D.DEPO_ID) AS ANNUL_TAX_PAYED_EQU,
		ISNULL(D.TOTAL_PAYED_AMOUNT, $0.00) AS TOTAL_PAYED_AMOUNT, dbo.get_equ(ISNULL(D.TOTAL_PAYED_AMOUNT, $0.00), D.ISO, @date) AS TOTAL_PAYED_AMOUNT_EQU,
		ISNULL(D.TOTAL_TAX_PAYED_AMOUNT, $0.00) AS TOTAL_TAX_PAYED_AMOUNT, ISNULL(D.TOTAL_TAX_PAYED_AMOUNT_EQU, $0.00) AS TOTAL_TAX_PAYED_AMOUNT_EQU,
		D.PERC_FLAGS, D.REALIZE_TYPE, D.REALIZE_COUNT, D.REALIZE_COUNT_TYPE,
		D.RESPONSIBLE_USER_ID, D.RESPONSIBLE_USER
FROM ' + @view_name + N' D INNER JOIN #tbl T ON T.DEPO_ID = D.DEPO_ID
LEFT OUTER JOIN dbo.CLIENT_ATTRIBUTES (NOLOCK) CA ON CA.CLIENT_NO = D.CLIENT_NO  AND CA.ATTRIB_CODE = ''WORK_SEGMENT''
WHERE (D.STATE BETWEEN 240 AND 249) AND ((@action_date IS NULL) OR (D.ANNULMENT_DATE > @action_date))'

EXEC sp_executesql @sql, N'@action_date smalldatetime, @date smalldatetime', @action_date, @date
DROP TABLE #tbl

GO
