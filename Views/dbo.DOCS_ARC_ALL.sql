SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[DOCS_ARC_ALL] AS

SELECT CASE WHEN D.PARENT_REC_ID > 0 THEN D.PARENT_REC_ID ELSE D.REC_ID END AS OP_NUM, 
	AD.ACCOUNT AS DEBIT, AC.ACCOUNT AS CREDIT, AD.DEPT_NO AS DEBIT_BRANCH_ID, AC.DEPT_NO AS CREDIT_BRANCH_ID,
    AD.BAL_ACC_ALT AS DEBIT_BAL_ACC, AC.BAL_ACC_ALT AS CREDIT_BAL_ACC,
	D.*
FROM dbo.OPS_ARC D(NOLOCK)
 INNER JOIN dbo.ACCOUNTS AD (NOLOCK) ON AD.ACC_ID = D.DEBIT_ID
 INNER JOIN dbo.ACCOUNTS AC (NOLOCK) ON AC.ACC_ID = D.CREDIT_ID
GO