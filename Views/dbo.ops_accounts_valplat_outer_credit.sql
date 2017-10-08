SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ops_accounts_valplat_outer_credit] AS

SELECT * FROM dbo.ACCOUNTS
WHERE IS_OFFBALANCE = 0				-- Balance account
	AND REC_STATE IN (1, 4, 8, 32)	-- Open, Only Credit, Only Budjet, Control
	AND ACC_TYPE = 4				-- Correspondent account
	AND ISO <> 'GEL'
GO
