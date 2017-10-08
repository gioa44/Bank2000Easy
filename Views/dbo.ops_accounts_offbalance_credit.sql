SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ops_accounts_offbalance_credit] AS

SELECT * FROM dbo.ACCOUNTS
WHERE IS_OFFBALANCE = 1
	AND REC_STATE IN (1, 4, 8, 32)	-- Open, Only Credit, Only Budjet, Control
GO
