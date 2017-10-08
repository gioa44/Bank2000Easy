SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DEPO_VW_OP_ACC_DATA_CONVERT]
AS
	SELECT
		OP_ID,
		DEPO_ID,
		OP_ACC_DATA.value('(row/@ISO)[1]', 'char(3)') AS ISO,
		OP_ACC_DATA.value('(row/@AMOUNT)[1]', 'money') AS AMOUNT,
		OP_ACC_DATA.value('(row/@DEPO_ACC_ID)[1]', 'int') AS DEPO_ACC_ID,
		OP_ACC_DATA.value('(row/@LOSS_ACC_ID)[1]', 'int') AS LOSS_ACC_ID,
		OP_ACC_DATA.value('(row/@ACCRUAL_ACC_ID)[1]', 'int') AS ACCRUAL_ACC_ID,
		OP_ACC_DATA.value('(row/@ACCRUE_AMOUNT)[1]', 'money') AS ACCRUE_AMOUNT,
		OP_ACC_DATA.value('(row/@ACCRUE_AMOUNT_EQU)[1]', 'money') AS ACCRUE_AMOUNT_EQU,
		OP_ACC_DATA.value('(row/@CALC_AMOUNT_1)[1]', 'money') AS CALC_AMOUNT_1,
		OP_ACC_DATA.value('(row/@TOTAL_CALC_AMOUNT_1)[1]', 'money') AS TOTAL_CALC_AMOUNT_1,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_DATE_1)[1]', 'smalldatetime') AS MIN_PROCESSING_DATE_1,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_TOTAL_CALC_AMOUNT_1)[1]', 'money') AS MIN_PROCESSING_TOTAL_CALC_AMOUNT_1,
		OP_ACC_DATA.value('(row/@FORMULA_2)[1]', 'varchar(255)') AS FORMULA_2,
		OP_ACC_DATA.value('(row/@CALC_AMOUNT_2)[1]', 'money') AS CALC_AMOUNT_2,
		OP_ACC_DATA.value('(row/@TOTAL_CALC_AMOUNT_2)[1]', 'money') AS TOTAL_CALC_AMOUNT_2,
		OP_ACC_DATA.value('(row/@LAST_CALC_DATE_2)[1]', 'smalldatetime') AS LAST_CALC_DATE_2,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_DATE_2)[1]', 'smalldatetime') AS MIN_PROCESSING_DATE_2,
		OP_ACC_DATA.value('(row/@MIN_PROCESSING_TOTAL_CALC_AMOUNT_2)[1]', 'money') AS MIN_PROCESSING_TOTAL_CALC_AMOUNT_2
	FROM dbo.DEPO_OP
	WHERE OP_TYPE = dbo.depo_fn_const_op_convert()
GO
