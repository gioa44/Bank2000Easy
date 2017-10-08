SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE FUNCTION [dbo].[LOAN_FN_GET_LOAN_EXECUTED_OPS](@start_date smalldatetime, 
	@end_date smalldatetime = NULL, @eng_version bit = 0, @op_types varchar(255) = NULL)
RETURNS
	@loan_data TABLE (
	LOAN_ID int NOT NULL,
	OP_ID int NULL,
	BRANCH_ID int NULL,
	DEPT_NO int NULL,
	STATE tinyint NULL,
	CLIENT_DESCRIP varchar(100) NULL,
	AGREEMENT_NO varchar(100) NULL,
	INSTALLMENT bit NULL,
	RESTRUCTURED int NULL,
	PROLONGED int NULL,
	LOAN_ISO TISO NULL,
	LOAN_AMOUNT money NULL,
	START_DATE smalldatetime NULL,
	END_DATE smalldatetime NULL,
	INTRATE money NULL,
	U_USER_NAME varchar(13) NULL,
	OP_DATE smalldatetime NULL,
	OP_TYPE smallint NULL,
	OP_DESCRIP varchar(150) NULL, 
	OP_ISO TISO NULL,
	OP_AMOUNT money NULL, 
	OP_DOC_REC_ID int NULL,
	EXECUTED bit NULL, 
	OWNER_U_NAME varchar(20) NULL, 
	AUTH_OWNER_U_NAME varchar(20) NULL)

AS
BEGIN
	IF @end_date IS NULL	
		SET @end_date = dbo.get_max_smalldatetime()	

	INSERT INTO @loan_data (LOAN_ID, OP_ID, BRANCH_ID, DEPT_NO, STATE, CLIENT_DESCRIP, AGREEMENT_NO, INSTALLMENT, RESTRUCTURED, PROLONGED, 
					LOAN_ISO, LOAN_AMOUNT, START_DATE,  END_DATE, INTRATE, U_USER_NAME, OP_DATE, OP_TYPE, OP_DESCRIP, OP_ISO, 
					OP_AMOUNT, OP_DOC_REC_ID, EXECUTED, OWNER_U_NAME, AUTH_OWNER_U_NAME )
	(SELECT L.LOAN_ID, NULL AS OP_ID, L.BRANCH_ID, L.DEPT_NO, L.STATE, L.CLIENT_DESCRIP, L.AGREEMENT_NO, L.INSTALLMENT, L.RESTRUCTURED, L.PROLONGED, 
			L.ISO AS LOAN_ISO, L.AMOUNT AS LOAN_AMOUNT, L.START_DATE, L.END_DATE, L.INTRATE, L.U_USER_NAME, NULL AS OP_DATE, NULL AS OP_TYPE, NULL AS OP_DESCRIP, NULL AS OP_ISO,
			NULL AS OP_AMOUNT, NULL AS OP_DOC_REC_ID, NULL AS EXECUTED, NULL AS OWNER_U_NAME, NULL AS AUTH_OWNER_U_NAME
		FROM dbo.LOAN_VW_LOANS L
		INNER JOIN dbo.LOAN_OPS O (NOLOCK) ON L.LOAN_ID = O.LOAN_ID
		INNER JOIN dbo.LOAN_OP_TYPES T (NOLOCK) ON O.OP_TYPE = T.TYPE_ID
	WHERE
		((ISNULL(@op_types, '')='') OR (EXISTS (SELECT * FROM dbo.fn_split_list_int(@op_types, default) WHERE ID=O.OP_TYPE))) AND 
		((@start_date is NULL) OR (O.OP_DATE >= @start_date)) AND ((@end_date is NULL) OR (O.OP_DATE <= @end_date))

	UNION 

	SELECT L.LOAN_ID, O.OP_ID, NULL AS BRANCH_ID, NULL AS DEPT_NO, NULL AS STATE, L.CLIENT_DESCRIP, L.AGREEMENT_NO, NULL AS INSTALLMENT, 
			NULL AS RESTRUCTURED, NULL AS PROLONGED, NULL AS LOAN_ISO, L.AMOUNT AS LOAN_AMOUNT, NULL AS START_DATE, NULL AS END_DATE, NULL AS INTRATE, 
			NULL AS U_USER_NAME, O.OP_DATE, O.OP_TYPE,
			CASE WHEN @eng_version = 0 THEN T.DESCRIP ELSE T.DESCRIP_LAT END AS OP_DESCRIP,
			L.ISO AS OP_ISO, O.AMOUNT AS OP_AMOUNT, O.DOC_REC_ID AS OP_DOC_REC_ID,
			CASE WHEN OP_STATE = 255 THEN 1 ELSE 0 END AS EXECUTED, 
			RTRIM(U.USER_NAME) + '@' + DP_U.ALIAS AS OWNER_U_NAME,
			CASE WHEN US.USER_NAME IS NULL THEN US.USER_NAME ELSE RTRIM(US.USER_NAME) + '@' + DP_US.ALIAS END AS AUTH_OWNER_U_NAME
		FROM dbo.LOAN_VW_LOANS L
		INNER JOIN dbo.LOAN_OPS O (NOLOCK) ON L.LOAN_ID = O.LOAN_ID
		INNER JOIN dbo.LOAN_OP_TYPES T (NOLOCK) ON O.OP_TYPE = T.TYPE_ID
		INNER JOIN dbo.USERS U (NOLOCK) ON O.OWNER = U.USER_ID
		INNER JOIN dbo.DEPTS DP_U (NOLOCK) ON DP_U.DEPT_NO = U.DEPT_NO
		LEFT JOIN dbo.USERS US (NOLOCK) ON O.AUTH_OWNER = US.USER_ID
		LEFT JOIN dbo.DEPTS DP_US (NOLOCK) ON DP_US.DEPT_NO = US.DEPT_NO

	WHERE
		((ISNULL(@op_types, '')='') OR (EXISTS (SELECT * FROM dbo.fn_split_list_int(@op_types, default) WHERE ID=O.OP_TYPE))) AND 
		((@start_date is NULL) OR (O.OP_DATE >= @start_date)) AND ((@end_date is NULL) OR (O.OP_DATE <= @end_date)) 
	)  ORDER BY L.LOAN_ID, OP_ID

RETURN
END

GO