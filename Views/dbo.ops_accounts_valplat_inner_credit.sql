SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ops_accounts_valplat_inner_credit] AS

SELECT * FROM dbo.ACCOUNTS
WHERE IS_OFFBALANCE = 0				-- Balance account
	AND REC_STATE IN (1, 4, 8, 32)	-- Open, Only Credit, Only Budjet, Control
	AND ACC_TYPE <> 2				-- Not Cash
	AND ISO <> 'GEL'
GO
