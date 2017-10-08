SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_DEPO_REP_LIST]
AS
SELECT D.DEPO_ID, D.STATE, D.DEPT_NO, DEPT.ALIAS, DEPT.DESCRIP AS DEPT_DESCRIP,
		D.CLIENT_NO, CL.DESCRIP AS CLIENT_DESCRIP, CL.COUNTRY, CL.IS_RESIDENT, CL.IS_INSIDER, ISNULL(CL.TAX_INSP_CODE, '') AS TAX_INSP_CODE,
		CL.CLIENT_TYPE, CT.DESCRIP AS CLIENT_TYPE_DESCRIP, CL.CLIENT_SUBTYPE, CST.DESCRIP AS CLIENT_SUBTYPE_DESCRIP, CS2.DESCRIP AS CLIENT_SUBTYPE2_DESCRIP,		
		D.PROD_ID, DP.CODE AS PROD_CODE, DP.PROD_NO AS PROD_NO, DP.DESCRIP AS PROD_DESCRIP,
		D.AGREEMENT_NO, D.DEPO_ACC_ID, DA.ACCOUNT AS DEPO_ACCOUNT,	DA.BAL_ACC_ALT AS DEPO_ACCOUNT_BAL_ACC,	D.ISO,
		D.ACCRUAL_ACC_ID, AA.ACCOUNT AS ACCRUAL_ACCOUNT, AA.BAL_ACC_ALT AS ACCRUAL_ACCOUNT_BAL_ACC,
		D.AGREEMENT_AMOUNT, D.AMOUNT,
		D.PERC_FLAGS, D.INTRATE, D.REAL_INTRATE, D.START_DATE, D.END_DATE, DATEDIFF(DAY, D.START_DATE, D.END_DATE) AS PERIOD_DAYS, D.ANNULMENT_DATE, D.DAYS_IN_YEAR,
		D.REALIZE_TYPE, D.REALIZE_COUNT, D.REALIZE_COUNT_TYPE,
		ISNULL(ACP.TOTAL_CALC_AMOUNT, $0.00) AS TOTAL_CALC_AMOUNT, ISNULL(ACP.TOTAL_PAYED_AMOUNT, $0.00) AS TOTAL_PAYED_AMOUNT, 
		ISNULL(ACP.CALC_AMOUNT, $0.00) AS CALC_AMOUNT, ISNULL(ACP.TOTAL_TAX_PAYED_AMOUNT, $0.00) AS TOTAL_TAX_PAYED_AMOUNT, ISNULL(ACP.TOTAL_TAX_PAYED_AMOUNT_EQU, $0.00) AS TOTAL_TAX_PAYED_AMOUNT_EQU, 
		ACP.LAST_MOVE_DATE,
		D.RESPONSIBLE_USER_ID, U.[USER_NAME] AS RESPONSIBLE_USER
	FROM dbo.DEPO_DEPOSITS D (NOLOCK)
		INNER JOIN dbo.DEPTS DEPT ON DEPT.DEPT_NO = D.DEPT_NO
		INNER JOIN dbo.CLIENTS CL ON D.CLIENT_NO = CL.CLIENT_NO
		INNER JOIN dbo.ACCOUNTS DA ON DA.ACC_ID = D.DEPO_ACC_ID
		INNER JOIN dbo.ACCOUNTS AA ON AA.ACC_ID = D.ACCRUAL_ACC_ID
		INNER JOIN dbo.DEPO_PRODUCT DP ON DP.PROD_ID = D.PROD_ID
		INNER JOIN dbo.USERS U ON D.RESPONSIBLE_USER_ID = U.[USER_ID]
		LEFT OUTER JOIN dbo.ACCOUNTS_CRED_PERC [ACP] ON ACP.ACC_ID = D.DEPO_ACC_ID
		LEFT OUTER JOIN dbo.CLIENT_TYPES CT ON CT.CLIENT_TYPE = CL.CLIENT_TYPE
		LEFT OUTER JOIN dbo.CLIENT_SUBTYPES CST ON CST.CLIENT_TYPE = CL.CLIENT_TYPE AND CST.CLIENT_SUBTYPE = CL.CLIENT_SUBTYPE
		LEFT OUTER JOIN dbo.CLIENT_SUBTYPES2 CS2 ON CS2.CLIENT_TYPE = CL.CLIENT_TYPE AND CS2.CLIENT_SUBTYPE2 = CL.CLIENT_SUBTYPE2
GO