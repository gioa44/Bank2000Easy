SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [impexp].[find_doc_assign_acc_id]
	@user_id int,
	@for_swift bit = 0,
	@acc_id int = NULL,
	@branch_id int = NULL,
	@client_name varchar(100) = NULL,
	@client_name_is_lat bit = 0,
	@search_in_account_names bit = 0,
	@account varchar(50) = NULL,
	@iso char(3) = NULL,
	@tax_id varchar(20) = NULL,
	@bic varchar(20) = NULL
AS

SET NOCOUNT ON;

DECLARE 
	@sql nvarchar(max)

IF @for_swift = 0 
	SET @sql = N'SELECT A.ACC_ID, DP.ALIAS AS BRANCH_ALIAS, A.ACCOUNT, A.ISO, DP.CODE9 AS BANK_CODE,' +
		N'C.DESCRIP AS CLIENT_NAME, A.DESCRIP AS ACCOUNT_NAME, ' + char(13) +
		N'AT.DESCRIP + '' '' + ISNULL(AST.DESCRIP,'''') AS ACC_DESCRIP ' + char(13) +
		N'FROM dbo.ACCOUNTS A (NOLOCK) ' + char(13) +
		N'LEFT JOIN dbo.CLIENTS C (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO ' + char(13) +
		N'LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = A.DEPT_NO ' + char(13) +
		N'LEFT JOIN dbo.ACC_TYPES AT (NOLOCK) ON AT.ACC_TYPE = A.ACC_TYPE ' + char(13) +
		N'LEFT JOIN dbo.ACC_SUBTYPES AST (NOLOCK) ON AST.ACC_TYPE = A.ACC_TYPE AND AST.ACC_SUBTYPE = A.ACC_SUBTYPE ' + char(13)
ELSE
	SET @sql = N'SELECT A.ACC_ID, DP.ALIAS AS BRANCH_ALIAS, A.ACCOUNT, A.ISO, DP.BIC AS BANK_CODE,' +
		N'C.DESCRIP AS CLIENT_NAME, C.DESCRIP_LAT AS CLIENT_NAME_LAT,' + char(13) +
		N'A.DESCRIP AS ACCOUNT_NAME, A.DESCRIP_LAT AS ACCOUNT_NAME_LAT,' + char(13) +
		N'AT.DESCRIP + '' '' + ISNULL(AST.DESCRIP,'''') AS ACC_DESCRIP ' + char(13) +
		N'FROM dbo.ACCOUNTS A (NOLOCK) ' + char(13) +
		N'LEFT JOIN dbo.CLIENTS C (NOLOCK) ON A.CLIENT_NO = C.CLIENT_NO ' + char(13) +
		N'LEFT JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = A.DEPT_NO ' + char(13) +
		N'LEFT JOIN dbo.ACC_TYPES AT (NOLOCK) ON AT.ACC_TYPE = A.ACC_TYPE ' + char(13) +
		N'LEFT JOIN dbo.ACC_SUBTYPES AST (NOLOCK) ON AST.ACC_TYPE = A.ACC_TYPE AND AST.ACC_SUBTYPE = A.ACC_SUBTYPE ' + char(13)

IF @acc_id IS NOT NULL 
BEGIN
	SET @sql = @sql + N'WHERE A.ACC_ID = @acc_id'
	EXEC sp_executesql @sql, N'@acc_id int', @acc_id
END
ELSE
BEGIN
	DECLARE @where nvarchar(1000)
	SET @where = N''

	IF @iso IS NOT NULL
		SET @where = @where + N' AND A.ISO = @iso'
	IF @branch_id IS NOT NULL
		SET @where = @where + N' AND A.BRANCH_ID = @branch_id'
	IF @account IS NOT NULL
		SET @where = @where + N' AND convert(varchar(20), A.ACCOUNT) LIKE @account'
	IF @client_name IS NOT NULL
	BEGIN
		SET @where = @where + N' AND (C.DESCRIP' + CASE WHEN @client_name_is_lat = 0 THEN N'' ELSE '_LAT' END + N' LIKE @client_name'
		IF @search_in_account_names <> 0
			SET @where = @where + N' OR A.DESCRIP' + CASE WHEN @client_name_is_lat = 0 THEN N'' ELSE '_LAT' END + N' LIKE @client_name)'
		ELSE
			SET @where = @where + N')'
	END
	IF @bic IS NOT NULL
		SET @where = @where + N' AND DP.BIC LIKE @bic'
	IF @tax_id IS NOT NULL
		SET @where = @where + N' AND (C.TAX_INSP_CODE LIKE @tax_id OR C.PERSONAL_ID LIKE @tax_id)'

	IF @where = N''
		SET @where = N'1 = 0'
	ELSE
		SET @sql = @sql + N'WHERE A.IS_OFFBALANCE = 0 AND A.REC_STATE NOT IN (2, 16, 64, 128)' + @where

	EXEC sp_executesql @sql, N'@branch_id int,@client_name varchar(100),@account varchar(50),@iso varchar(3),@tax_id varchar(20),@bic varchar(20)', 
		@branch_id, @client_name, @account, @iso, @tax_id, @bic
END
GO
