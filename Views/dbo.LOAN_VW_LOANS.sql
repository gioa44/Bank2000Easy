SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOANS]
AS
SELECT
	L.LOAN_ID, L.ROW_VERSION, L.BRANCH_ID, L.DEPT_NO, L.AUTHORIZE_LEVEL, L.STATE,
	DP.ALIAS AS BRANCH_ALIAS, DP.ALIAS + ': ' + DP.DESCRIP AS BRANCH_NAME,
	L.PRODUCT_ID, P.CODE AS PRODUCT_CODE, L.AGREEMENT_NO,
	L.CLIENT_NO, L.CLIENT_SUBTYPE2, C.DESCRIP AS CLIENT_DESCRIP, C.DESCRIP_LAT AS CLIENT_DESCRIP_LAT,
	L.REG_DATE, L.ISO, L.AMOUNT, L.DISBURSE_AMOUNT, L.START_DATE, L.PERIOD, L.END_DATE,
	C.IS_RESIDENT, C.IS_INSIDER, C.IS_EMPLOYEE, C.IS_IN_BLACK_LIST, L.CREDIT_LINE_ID, L.LOAN_TYPE,
	L.DISBURSE_TYPE, L.ENSURE_TYPE, L.INSTALLMENT, L.EVENT_INSTALLMENT, L.RESTRUCTURED, L.PROLONGED, 
	L.INTRATE, L.PENALTY_INTRATE, L.PREPAYMENT_INTRATE,
	L.PREPAYMENT_STEP, L.NOTUSED_INTRATE, L.ADMIN_INTRATE, L.ADMIN_FEE,
	L.RISK_TYPE, L.RISK_PERC_RATE_1, L.RISK_PERC_RATE_2, L.RISK_PERC_RATE_3, L.RISK_PERC_RATE_4, L.RISK_PERC_RATE_5,
	L.WRITEOFF_DATE, L.CALLOFF_DATE, L.INTEREST_FLAGS,
	L.PENALTY_FLAGS, L.PREPAYMENT_FLAGS, L.PAYMENT_INTERVAL_TYPE,
	LPI.DESCRIP AS LPI_DESCRIP,
	LPI.DESCRIP_LAT AS LPI_DESCRIP_LAT,
	LPI.INTERVAL AS LPI_INTERVAL, L.SCHEDULE_TYPE,
	L.PAYMENT_DAY, L.RESERVE_MAX_CATEGORY,
	L.INSTALLMENT_PERCENT, L.GRACE_STEPS, L.GRACE_TYPE,
	L.BASIS, L.RESPONSIBLE_USER_ID, L.CORESPONSIBLE_USER_ID, L.PURPOSE_TYPE, L.BAL_ACC,
	LS.DESCRIP AS LS_DESCRIP, 
	LS.DESCRIP_LAT AS LS_DESCRIP_LAT,
	RTRIM(U.USER_NAME) + '@' + DP.ALIAS AS U_USER_NAME,	
	L.GROUP_ID, LG.CODE AS LG_CODE, L.CLIENT_ACCOUNT,
	L.INSURANCE_RATE, SERVICE_FEE_RATE, L.SERVICE_FEE, L.LINKED_CCY, L.INDEXED_RATE, 
	L.MAIN_COLLATERAL_LIST, L.PMT, L.GRACE_FINISH_DATE, L.CLOSE_DATE, L.GUARANTEE, L.INTERNAT_GUARANTEE, L.IMMEDIATE_FEEING
FROM dbo.LOANS L (NOLOCK)
	INNER JOIN dbo.DEPTS DP (NOLOCK) ON DP.DEPT_NO = L.DEPT_NO
	INNER JOIN dbo.LOAN_PRODUCTS P (NOLOCK) ON P.PRODUCT_ID = L.PRODUCT_ID
	INNER JOIN dbo.LOAN_PAYMENT_INTERVALS LPI (NOLOCK) ON LPI.TYPE_ID = L.PAYMENT_INTERVAL_TYPE
	INNER JOIN dbo.LOAN_STATES LS (NOLOCK) ON LS.STATE = L.STATE
	INNER JOIN dbo.USERS U (NOLOCK) ON U.USER_ID = L.RESPONSIBLE_USER_ID
	INNER JOIN dbo.CLIENTS C (NOLOCK) ON C.CLIENT_NO = L.CLIENT_NO
	LEFT OUTER JOIN dbo.LOAN_GROUPS LG (NOLOCK) ON  LG.GROUP_ID = L.GROUP_ID
GO
