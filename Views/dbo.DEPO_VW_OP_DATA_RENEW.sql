SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_DATA_RENEW]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_DATA.value('(row/@RENEW_CAPITALIZED)[1]', 'bit') AS RENEW_CAPITALIZED,		
		OP_DATA.value('(row/@PREV_START_DATE)[1]', 'smalldatetime') AS PREV_START_DATE,
		OP_DATA.value('(row/@PREV_PERIOD)[1]', 'int') AS PREV_PERIOD,		
		OP_DATA.value('(row/@PREV_END_DATE)[1]', 'smalldatetime') AS PREV_END_DATE,
		OP_DATA.value('(row/@PREV_AGREEMENT_AMOUNT)[1]', 'money') AS PREV_AGREEMENT_AMOUNT,
		OP_DATA.value('(row/@PREV_DEPO_AMOUNT)[1]', 'money') AS PREV_DEPO_AMOUNT,
		OP_DATA.value('(row/@INTEREST_AMOUNT)[1]', 'money') AS INTEREST_AMOUNT,
		OP_DATA.value('(row/@INTEREST_TAX_AMOUNT)[1]', 'money') AS INTEREST_TAX_AMOUNT,
		OP_DATA.value('(row/@PREV_INTRATE)[1]', 'money') AS PREV_INTRATE,
		OP_DATA.value('(row/@PREV_REAL_INTRATE)[1]', 'decimal(32,12)') AS PREV_REAL_INTRATE,
		OP_DATA.value('(row/@PREV_SPEND_CONST_AMOUNT)[1]', 'money') AS PREV_SPEND_CONST_AMOUNT,
		OP_DATA.value('(row/@PREV_FORMULA)[1]', 'varchar(255)') AS PREV_FORMULA,		
		
		OP_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS START_DATE,
		OP_DATA.value('(row/@PERIOD)[1]', 'int') AS PERIOD,
		OP_DATA.value('(row/@CORRECTION)[1]', 'int') AS CORRECTION,
		OP_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_DATA.value('(row/@INTRATE)[1]', 'money') AS INTRATE,
		OP_DATA.value('(row/@AGREEMENT_AMOUNT)[1]', 'money') AS AGREEMENT_AMOUNT,		

		OP_DATA.value('(row/@RENEW_COUNT)[1]', 'int') AS RENEW_COUNT,
		OP_DATA.value('(row/@MAX_RENEW_COUNT)[1]', 'int') AS MAX_RENEW_COUNT,
		OP_DATA.value('(row/@ARCHIVE_DEPOSIT)[1]', 'bit') AS ARCHIVE_DEPOSIT,
		OP_DATA.value('(row/@GENERATE_NEW_SCHEDULE)[1]', 'bit') AS GENERATE_NEW_SCHEDULE

	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_renew()
GO
