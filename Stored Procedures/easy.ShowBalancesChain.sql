SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [easy].[ShowBalancesChain]
	@StartDate datetime,
	@EndDate datetime
AS
/*
CREATE SCHEMA easy
GO

sp_configure 'show advanced options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO
-----------------------------------------------------
sp_configure 'Ad Hoc Distributed Queries', 0
RECONFIGURE;
GO
sp_configure 'show advanced options', 0
RECONFIGURE;
GO

exec easy.ShowBalancesChain '20140715', '20140715'
*/

CREATE TABLE Balances1Day(
	--BalanceDate datetime Not Null,
	BAL_ACC TBAL_ACC Null,
	ISO TISO Null,
	DBN money Not Null,
	CRN money Not Null,
	--DIFF_N money Not Null,
	DBO money Not Null,
	CRO money Not Null,
	--DIFF_O money Not Null,
	DBK money Not Null,
	CRK money Not Null,
	--DIFF_K money Not Null,	
	ACT_PAS bit Null,
	DESCRIP varchar(400) Null,
	REC_INFO varchar(50) Null	
)

SET NOCOUNT ON;

IF OBJECT_ID('dbo.BalancesChain') <> 0
	DROP TABLE dbo.BalancesChain

CREATE TABLE BalancesChain(
	BalanceDate datetime Not Null,
	BalAcc TBAL_ACC Null,
	Ccy TISO Null,
	DebitTurn money Not Null,
	CreditTurn money Not Null,
	BalanceDebit money Not Null,
	BalanceCredit money Not Null,
	--DIFF_K money Not Null,	
	--ACT_PAS bit Null,
	--Descrip nvarchar(400) Null
	--REC_INFO varchar(50) Null
)

DECLARE
	@date datetime,
	@date_str varchar(50),
	@sql nvarchar(max)
	
SET @date = @StartDate
	
WHILE @date <= @EndDate
BEGIN
	SET @date_str = CONVERT(varchar(50), @date, 126)
	SET @sql = N'	
	DELETE FROM Balances1Day
	
	INSERT INTO Balances1Day
	SELECT a.*
	FROM OPENROWSET(''SQLOLEDB'', ''Server=serversql1;Trusted_Connection=yes'',
		 ''SET NOCOUNT ON; SET FMTONLY OFF; EXEC BANK2000.dbo.show_balance @tree=0,@group_field_list='+quotename('BAL_ACC,ISO') + ',@oob=1,@equ=0,@turns=1,
		 @start_date='''''+ @date_str + ''''', @end_date='''''+ @date_str + ''''',
		 @iso=''''' + '***' + ''''',@branch_str=''''' + '0' + ''''',@shadow_level=-1,@clean=0,@sub_bal_acc=1,@is_lat=0,@user_id=10'') AS a
	'
	PRINT @sql
	EXEC sp_executesql @sql
	
	INSERT INTO BalancesChain (BalanceDate, BalAcc, Ccy, DebitTurn, CreditTurn, BalanceDebit, BalanceCredit)
	SELECT @date, BAL_ACC, ISO, DBO, CRO, DBK, CRK--, dbo.clr_ansi_to_unicode(DESCRIP)
	FROM Balances1Day WHERE ISO IS NOT NULL
	ORDER BY BAL_ACC, ISO
	
	SET @date = @date + 1
END

SELECT * FROM BalancesChain
DROP TABLE Balances1Day
DROP TABLE BalancesChain
GO
