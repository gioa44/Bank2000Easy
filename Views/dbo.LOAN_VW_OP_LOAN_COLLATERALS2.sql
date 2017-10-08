SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_OP_LOAN_COLLATERALS2]
AS
	SELECT
		l.OP_ID,
		l.CREDIT_LINE_ID,
		T.c.value('./@COLLATERAL_ID', 'int') AS COLLATERAL_ID,
		T.c.value('./@ROW_VERSION', 'int') AS ROW_VERSION,
		T.c.value('./@LOAN_ID', 'int') AS LOAN_ID,
		T.c.value('./@CLIENT_NO', 'int') AS CLIENT_NO,
		T.c.value('./@OWNER', 'int') AS OWNER,
		T.c.value('./@ISO', 'char(3)') AS ISO,
		T.c.value('./@COLLATERAL_TYPE', 'int') AS COLLATERAL_TYPE,
		T.c.value('./@AMOUNT', 'money') AS AMOUNT,
		T.c.value('./@DESCRIP', 'varchar(2000)') AS DESCRIP,
		T.c.value('./@MARKET_AMOUNT', 'money') AS MARKET_AMOUNT,
		T.c.value('./@IS_ENSURED', 'bit') AS IS_ENSURED,
		T.c.value('./@ENSURANCE_PAYMENT_AMOUNT', 'money') AS ENSURANCE_PAYMENT_AMOUNT,
		T.c.value('./@ENSUR_PAYMENT_INTERVAL_TYPE', 'int') AS ENSUR_PAYMENT_INTERVAL_TYPE,
		T.c.value('./@ENSURANCE_COMPANY_ID', 'int') AS ENSURANCE_COMPANY_ID,
		T.c.value('./@IS_LINKED', 'bit') AS IS_LINKED,
		T.c.value('./@MAIN', 'bit') AS MAIN,
		CONVERT(XML, T.c.value('./@XML_STR', 'varchar(max)')) AS XML_STR
	FROM dbo.LOAN_GEN_AGREE_OPS l
		CROSS APPLY l.OP_EXT_XML.nodes('/root/row') AS  T(c)
	WHERE OP_TYPE IN (dbo.loan_const_gen_agree_op_restruct_collat(), dbo.loan_const_gen_agree_op_correct_collat(), dbo.loan_const_gen_agree_op_close())
GO
