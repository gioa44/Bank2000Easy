SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[LOAN_VW_LOAN_OP_RESTRUCTURE_COLLATERAL]
AS
SELECT
		OP_ID,
		LOAN_ID
	FROM dbo.LOAN_OPS
	WHERE OP_TYPE IN (dbo.loan_const_op_restructure_collateral(), dbo.loan_const_op_correct_collateral())

GO
