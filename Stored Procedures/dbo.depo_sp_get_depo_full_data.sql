SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[depo_sp_get_depo_full_data]
	@depo_id int,
	@op_id int = NULL
AS
BEGIN
	SELECT 	D.DEPO_ID, D.ROW_VERSION, 
			D.BRANCH_ID, D.DEPT_NO, DPT.DESCRIP AS DEPT_DESCRIP,			
			D.[STATE], D.ALARM_STATE,

			D.CLIENT_NO, C.DESCRIP AS CLIENT_DESCRIP, C.CLIENT_TYPE,

			D.TRUST_DEPOSIT, D.TRUST_CLIENT_NO, TC.DESCRIP AS TRUST_CLIENT_DESCRIP,  D.TRUST_EXTRA_INFO,
 
			D.PROD_ID, P.CODE AS PROD_CODE, P.PROD_NO, P.DESCRIP AS PROD_DESCRIP, 
			P.ANALYZE_SCHEMA,
			CASE WHEN P.ANALYZE_SCHEMA IS NULL THEN 'N/A' ELSE DPAS.DESCRIP  END AS ANALYZE_SCHEMA_DESCRIP,
			P.ANALYZE_SCHEMA_ANNUL,
			D.AGREEMENT_NO, D.DEPO_TYPE, 
	
			D.DEPO_ACC_SUBTYPE, 
			ASBT.DESCRIP AS DEPO_ACC_SUBTYPE_DESCRIP,
	
			D.DEPO_ACCOUNT_STATE, D.ISO, D.AGREEMENT_AMOUNT, D.AMOUNT, D.DATE_TYPE,
			D.PERIOD, D.[START_DATE], D.END_DATE, D.INTRATE, D.PERC_FLAGS, D.DAYS_IN_YEAR, D.FORMULA, 
			D.INTRATE_SCHEMA, PIS.DESCRIP AS INTRATE_SCHEMA_DESCRIP,
			D.ACCRUE_TYPE, D.REALIZE_SCHEMA, D.REALIZE_TYPE, D.REALIZE_COUNT, D.REALIZE_COUNT_TYPE, D.DEPO_REALIZE_SCHEMA, 
			D.DEPO_REALIZE_SCHEMA_AMOUNT, D.RECALCULATE_TYPE,
			
			ID.ISO as INIT_ISO, ID.AGREEMENT_AMOUNT AS INIT_AGREEMENT_AMOUNT, ID.INTRATE AS INIT_INTRATE,
			
			D.CONVERTIBLE, 

			D.PROLONGABLE, 
			CASE WHEN D.PROLONGABLE = 1 THEN D.PROLONGATION_COUNT ELSE NULL END AS PROLONGATION_COUNT,
			
			D.RENEWABLE, D.RENEW_CAPITALIZED,
			CASE WHEN D.RENEWABLE = 1 THEN D.RENEW_MAX ELSE NULL END AS RENEW_MAX,
			CASE WHEN D.RENEWABLE = 1 THEN CASE WHEN D.RENEW_COUNT IS NULL THEN 0 ELSE D.RENEW_COUNT END ELSE NULL END AS RENEW_COUNT,
			CASE WHEN D.RENEWABLE = 1 THEN D.RENEW_LAST_PROD_ID ELSE NULL END AS RENEW_LAST_PROD_ID,
			CASE WHEN D.RENEWABLE = 1 THEN D.LAST_RENEW_DATE ELSE NULL END AS LAST_RENEW_DATE,
			
			D.SHAREABLE, D.SHARED_CONTROL_CLIENT_NO, D.SHARED_CONTROL, 
			CSRD.DESCRIP AS SHARED_CONTROL_CLIENT_DESCRIP,
			
			D.REVISION_SCHEMA,
			D.REVISION_TYPE, D.REVISION_COUNT, D.REVISION_COUNT_TYPE,
			D.REVISION_GRACE_ITEMS, D.REVISION_GRACE_DATE_TYPE,

			D.ANNULMENTED, D.ANNULMENT_REALIZE, D.ANNULMENT_SCHEMA, D.ANNULMENT_SCHEMA_ADVANCE, D.ANNULMENT_DATE,
			ANNL.DESCRIP AS ANNULMENT_SCHEMA_DESCRIP,
			D.ANNULMENT_SCHEMA_ADVANCE,
			CASE WHEN D.ANNULMENT_SCHEMA_ADVANCE IS NULL THEN 'N/A' ELSE ANLADV.DESCRIP END AS ANNULMENT_SCHEMA_ADV_DESCRIP,
			BNS.[SCHEMA_ID] AS BONUS_SCHEMA,
			CASE WHEN P.BONUS_SCHEMA IS NULL THEN 'N/A' ELSE BNS.DESCRIP  END AS BONUS_SCHEMA_DESCRIP,

			D.INTEREST_REALIZE_ADV, D.INTEREST_REALIZE_ADV_AMOUNT, 
			
			D.CHILD_DEPOSIT, D.CHILD_CONTROL_OWNER, 
			D.CHILD_CONTROL_CLIENT_NO_1,
			CHLD1.DESCRIP AS CHILD_CONTROL_CLIENT_DESCRIP_1,
			D.CHILD_CONTROL_CLIENT_NO_2,
			CHLD2.DESCRIP AS CHILD_CONTROL_CLIENT_DESCRIP_2,
			
			D.ACCUMULATIVE, D.ACCUMULATE_PRODUCT, 
			CASE WHEN D.ACCUMULATIVE = 1 THEN D.ACCUMULATE_MIN ELSE NULL END AS ACCUMULATE_MIN,
			CASE WHEN D.ACCUMULATIVE = 1 THEN D.ACCUMULATE_MAX ELSE NULL END AS ACCUMULATE_MAX,
			CASE WHEN D.ACCUMULATIVE = 1 THEN D.ACCUMULATE_AMOUNT ELSE NULL END AS ACCUMULATE_AMOUNT,
			CASE WHEN D.ACCUMULATIVE = 1 THEN D.ACCUMULATE_MAX_AMOUNT ELSE NULL END AS ACCUMULATE_MAX_AMOUNT,
			CASE WHEN D.ACCUMULATIVE = 1 THEN D.ACCUMULATE_SCHEMA_INTRATE ELSE NULL END AS ACCUMULATE_SCHEMA_INTRATE,
			
			D.SPEND, 
			CASE WHEN D.SPEND = 1 THEN D.SPEND_INTRATE ELSE NULL END AS SPEND_INTRATE,
			CASE WHEN D.SPEND = 1 THEN DPP.SPEND_TYPE ELSE NULL END AS SPEND_TYPE,
			CASE WHEN D.SPEND = 1 THEN D.SPEND_AMOUNT ELSE NULL END AS SPEND_AMOUNT,
			CASE WHEN D.SPEND = 1 THEN DPP.SPEND_INTRATE  ELSE NULL END AS SPEND_AMOUNT_INTRATE,
			CASE WHEN D.SPEND = 1 THEN D.SPEND_CONST_AMOUNT ELSE NULL END AS SPEND_CONST_AMOUNT,
			
			D.CREDITCARD_BALANCE_CHECK,
			
			D.DEPO_FILL_ACC_ID, D.DEPO_ACC_ID, D.LOSS_ACC_ID, D.ACCRUAL_ACC_ID,
			D.DEPO_REALIZE_ACC_ID, D.INTEREST_REALIZE_ACC_ID, D.INTEREST_REALIZE_ADV_ACC_ID,
			U.[USER_NAME] AS RESPONSIBLE_USER, D.DEPO_NOTE, D.ALARM_NOTE, D.DEPOSIT_DEFAULT
  FROM dbo.depo_get_depo_full_data(@depo_id, @op_id) D 
		INNER JOIN dbo.CLIENTS C (NOLOCK) ON D.CLIENT_NO = C.CLIENT_NO
		INNER JOIN dbo.USERS U ON D.RESPONSIBLE_USER_ID = U.[USER_ID]
		INNER JOIN dbo.DEPO_PRODUCT P (NOLOCK) ON D.PROD_ID = P.PROD_ID
		INNER JOIN dbo.DEPO_PRODUCT_PROPERTIES DPP (NOLOCK) ON D.ISO = DPP.ISO AND D.PROD_ID = DPP.PROD_ID		
		INNER JOIN dbo.DEPO_PRODUCT_INTRATE_SCHEMA PIS (NOLOCK) ON D.INTRATE_SCHEMA = PIS.[SCHEMA_ID]
		INNER JOIN dbo.DEPTS DPT (NOLOCK) ON D.DEPT_NO = DPT.DEPT_NO
		INNER JOIN dbo.ACC_SUBTYPES ASBT (NOLOCK) ON D.DEPO_ACC_SUBTYPE = ASBT.ACC_SUBTYPE
		INNER JOIN dbo.depo_get_depo_full_data(@depo_id, 0) ID ON D.DEPO_ID = ID.DEPO_ID
		LEFT OUTER JOIN dbo.CLIENTS CHLD1 (NOLOCK) ON D.CHILD_CONTROL_CLIENT_NO_1 = CHLD1.CLIENT_NO
		LEFT OUTER JOIN dbo.CLIENTS CHLD2 (NOLOCK) ON D.CHILD_CONTROL_CLIENT_NO_2 = CHLD2.CLIENT_NO
		LEFT OUTER JOIN dbo.CLIENTS CSRD (NOLOCK) ON D.SHARED_CONTROL_CLIENT_NO = CSRD.CLIENT_NO
		LEFT OUTER JOIN dbo.CLIENTS TC (NOLOCK) ON D.TRUST_CLIENT_NO = TC.CLIENT_NO
		LEFT OUTER JOIN dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA ANNL (NOLOCK) ON D.ANNULMENT_SCHEMA = ANNL.[SCHEMA_ID]
		LEFT OUTER JOIN dbo.DEPO_PRODUCT_ANNULMENT_SCHEMA_ADVANCE ANLADV (NOLOCK) ON D.ANNULMENT_SCHEMA_ADVANCE = ANLADV.[SCHEMA_ID]
		LEFT OUTER JOIN dbo.DEPO_PRODUCT_BONUS_SCHEMA BNS (NOLOCK) ON P.BONUS_SCHEMA = BNS.[SCHEMA_ID]
		LEFT OUTER JOIN dbo.DEPO_PRODUCT_ANALYZE_SCHEMA DPAS (NOLOCK) ON P.ANALYZE_SCHEMA = DPAS.[SCHEMA_ID]
END

GO
