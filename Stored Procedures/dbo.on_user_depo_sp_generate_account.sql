SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[on_user_depo_sp_generate_account]
	@account		TACCOUNT OUTPUT,  
	@template		varchar(150),
	@branch_id		int,
	@dept_id		int,
	@bal_acc		TBAL_ACC,  
	@depo_bal_acc	TBAL_ACC = NULL,
	@client_no		int, 
	@ccy			TISO, 
	@prod_code4		int
AS


RETURN 0
GO
