SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ON_USER_LOAN_SP_GENERATE_ACCOUNT]
		@account		TACCOUNT OUTPUT,  
		@template		varchar(150),
		@branch_id		int,
		@dept_id		int,
		@bal_acc		TBAL_ACC,  
		@loan_bal_acc	TBAL_ACC,
		@client_no		int, 
		@ccy			TISO, 
		@loan_ccy		TISO,
		@prod_code3		int,
		@loan_no		int 
	AS

RETURN 0
GO
