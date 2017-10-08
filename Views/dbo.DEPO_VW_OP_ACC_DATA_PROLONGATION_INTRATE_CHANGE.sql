SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_ACC_DATA_PROLONGATION_INTRATE_CHANGE]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_ACC_DATA.value('(row/@ACC_ID)[1]', 'int') AS ACC_ID,
		OP_ACC_DATA.value('(row/@START_DATE)[1]', 'smalldatetime') AS [START_DATE],
		OP_ACC_DATA.value('(row/@END_DATE)[1]', 'smalldatetime') AS END_DATE,
		OP_ACC_DATA.value('(row/@MOVE_COUNT)[1]', 'smallint') AS MOVE_COUNT,
		OP_ACC_DATA.value('(row/@MOVE_COUNT_TYPE)[1]', 'tinyint') AS MOVE_COUNT_TYPE,
		OP_ACC_DATA.value('(row/@CALC_TYPE)[1]', 'tinyint') AS CALC_TYPE,
		OP_ACC_DATA.value('(row/@FORMULA)[1]', 'varchar(255)') AS FORMULA,
		OP_ACC_DATA.value('(row/@CLIENT_ACCOUNT)[1]', 'int') AS CLIENT_ACCOUNT,
		OP_ACC_DATA.value('(row/@PERC_CLIENT_ACCOUNT)[1]', 'int') AS PERC_CLIENT_ACCOUNT,
		OP_ACC_DATA.value('(row/@PERC_BANK_ACCOUNT)[1]', 'int') AS PERC_BANK_ACCOUNT,
		OP_ACC_DATA.value('(row/@DAYS_IN_YEAR)[1]', 'smallint') AS DAYS_IN_YEAR,
		OP_ACC_DATA.value('(row/@CALC_AMOUNT)[1]', 'money') AS CALC_AMOUNT,
		OP_ACC_DATA.value('(row/@TOTAL_CALC_AMOUNT)[1]', 'money') AS TOTAL_CALC_AMOUNT,
		OP_ACC_DATA.value('(row/@TOTAL_PAYED_AMOUNT)[1]', 'money') AS TOTAL_PAYED_AMOUNT,
		OP_ACC_DATA.value('(row/@LAST_CALC_DATE)[1]', 'smalldatetime') AS LAST_CALC_DATE,
		OP_ACC_DATA.value('(row/@LAST_MOVE_DATE)[1]', 'smalldatetime') AS LAST_MOVE_DATE,
		OP_ACC_DATA.value('(row/@PERC_FLAGS)[1]', 'int') AS PERC_FLAGS,
		OP_ACC_DATA.value('(row/@PERC_TYPE)[1]', 'tinyint') AS PERC_TYPE,
		OP_ACC_DATA.value('(row/@TAX_RATE)[1]', 'money') AS TAX_RATE,
		OP_ACC_DATA.value('(row/@START_DATE_TYPE)[1]', 'tinyint') AS START_DATE_TYPE,
		OP_ACC_DATA.value('(row/@START_DATE_DAYS)[1]', 'int') AS START_DATE_DAYS,
		OP_ACC_DATA.value('(row/@DATE_TYPE)[1]', 'tinyint') AS DATE_TYPE,
		OP_ACC_DATA.value('(row/@DEPO_ID)[1]', 'int') AS SCHEMA_DEPO_ID,
		OP_ACC_DATA.value('(row/@RECALCULATE_TYPE)[1]', 'tinyint') AS RECALCULATE_TYPE,
		OP_ACC_DATA.value('(row/@DEPO_REALIZE_ACC_ID)[1]', 'int') AS DEPO_REALIZE_ACC_ID,
		OP_ACC_DATA.value('(row/@INTEREST_REALIZE_ACC_ID)[1]', 'int') AS INTEREST_REALIZE_ACC_ID,
		OP_ACC_DATA.value('(row/@DEPO_REALIZE_AMOUNT)[1]', 'money') AS DEPO_REALIZE_AMOUNT,
		OP_ACC_DATA.value('(row/@INTEREST_REALIZE_AMOUNT)[1]', 'money') AS INTEREST_REALIZE_AMOUNT,
		OP_ACC_DATA.value('(row/@ADVANCE_ACC_ID)[1]', 'int') AS ADVANCE_ACC_ID,
		OP_ACC_DATA.value('(row/@ADVANCE_AMOUNT)[1]', 'money') AS ADVANCE_AMOUNT,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_DATE)[1]', 'smalldatetime') AS MIN_PROCESSING_DATE,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_TOTAL_CALC_AMOUNT)[1]', 'money') AS MIN_PROCESSING_TOTAL_CALC_AMOUNT,
		OP_ACC_DATA.value('(row/@TOTAL_TAX_PAYED_AMOUNT)[1]', 'money') AS TOTAL_TAX_PAYED_AMOUNT,
		OP_ACC_DATA.value('(row/@TOTAL_TAX_PAYED_AMOUNT_EQU)[1]', 'money') AS TOTAL_TAX_PAYED_AMOUNT_EQU
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_prolongation_intrate_change()
GO
