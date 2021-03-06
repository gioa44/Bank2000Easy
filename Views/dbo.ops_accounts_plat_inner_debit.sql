SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ops_accounts_plat_inner_debit] AS
SELECT * FROM dbo.ACCOUNTS
WHERE IS_OFFBALANCE = 0				-- Balance account
	AND REC_STATE IN (1, 8, 32)		-- Open, Only Budjet, Control
	AND NOT ACC_TYPE IN (2,4)		-- Not Cash
	AND ISO = 'GEL' 
	AND IS_INCASSO = 0
GO
