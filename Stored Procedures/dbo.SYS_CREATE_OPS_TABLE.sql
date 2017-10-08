SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[SYS_CREATE_OPS_TABLE] (@year int, @is_first bit)
AS

DECLARE 
  @sql nvarchar(2000),
  @s nvarchar(4),
  @s1 nvarchar(4)

SET @s = dbo.sys_get_arc_table_suffix(@year)
SET @s1 = dbo.sys_get_arc_table_suffix(@year+1)

SET @sql = N'IF OBJECT_ID(''' + dbo.sys_get_arc_table_name('OPS',@year) + ''')<>0 DROP TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year)
EXEC sp_executesql @sql

SET @sql = N'CREATE TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + '(
	REC_ID int NOT NULL ' + CASE WHEN @year = 0 THEN 'IDENTITY(1,1)' ELSE '' END + ',
	UID int NOT NULL,
	DOC_DATE smalldatetime NOT NULL,
	DOC_DATE_IN_DOC smalldatetime NULL,
	ISO TISO NOT NULL,
	AMOUNT money NOT NULL,
	AMOUNT_EQU money NOT NULL,
	DOC_NUM int NULL,
	OP_CODE TOPCODE NULL,
	DEBIT_ID int NOT NULL,
	CREDIT_ID int NOT NULL,
	REC_STATE tinyint NOT NULL,
	BNK_CLI_ID int NULL,
	DESCRIP varchar(150) NULL,
	PARENT_REC_ID int NULL,
	OWNER int NOT NULL,
	DOC_TYPE smallint NOT NULL,
	ACCOUNT_EXTRA TACCOUNT NULL,
	PROD_ID int NULL,
	FOREIGN_ID int NULL,
	CHANNEL_ID int NULL,
	DEPT_NO int NULL,
	IS_SUSPICIOUS bit NOT NULL,
	CASHIER int NULL,
	CHK_SERIE varchar(4) NULL,
	CASH_AMOUNT money NULL,
	TREASURY_CODE varchar(9) NULL,
	TAX_CODE_OR_PID varchar(11) NULL,
	RELATION_ID int NULL,
	FLAGS int NOT NULL,
	BRANCH_ID int NULL)'
IF @year <> 0
  SET @sql = @sql + ' ON [ARCHIVE]'

EXEC sp_executesql @sql

SET @sql = N'ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' ADD CONSTRAINT PK_' + dbo.sys_get_arc_table_name('OPS',@year) + N' PRIMARY KEY CLUSTERED (REC_ID)'

EXEC sp_executesql @sql

SET @sql = N'ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' ADD CONSTRAINT CK_' + dbo.sys_get_arc_table_name('OPS',@year) + N' '

DECLARE 
  @max_date smalldatetime,
  @dt smalldatetime,
  @max_s nvarchar(10)

SET @dt = dbo.bank_open_date()
IF YEAR(@dt) = @year OR @year = 0
  SET @max_s = dbo.sys_get_date_str (@dt)
ELSE 
  SET @max_s = @s1 + '0101'

SET @max_s = '''' + @max_s + ''''

IF @year = 0
  SET @sql = @sql + N'CHECK (DOC_DATE >= ' + @max_s + N')'
ELSE
IF @is_first = 1
  SET @sql = @sql + N'CHECK (DOC_DATE < ' + @max_s + N')'
ELSE
  SET @sql = @sql + N'CHECK (DOC_DATE >= ''' + @s + '0101'' AND DOC_DATE < ' + @max_s + N')'

EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_DT ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(DOC_DATE)'
EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_OWNER ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(OWNER)'
EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_ISO ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(ISO)'
EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_DOC_TYPE ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(DOC_TYPE)'
EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_PARENT_REC_ID ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(PARENT_REC_ID)'
EXEC sp_executesql @sql

SET @sql = N'CREATE NONCLUSTERED INDEX IX_' + dbo.sys_get_arc_table_name('OPS',@year) + '_ACC_EXTRA ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N'(ACCOUNT_EXTRA)'
EXEC sp_executesql @sql

SET @sql = N'ALTER TABLE dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' ADD CONSTRAINT DF_' + dbo.sys_get_arc_table_name('OPS',@year) + N'_FLAGS DEFAULT 0 FOR FLAGS'
EXEC sp_executesql @sql

IF @year <> 0
BEGIN
	SET @sql = 
		N'CREATE TRIGGER dbo.ON_' + dbo.sys_get_arc_table_name('OPS',@year) + '_INSERT' + char(13) +
		N'ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' AFTER INSERT AS' + char(13) + char(13) +

		N'SET NOCOUNT ON' + char(13) + char(13) +

		N'INSERT INTO dbo.' + dbo.sys_get_arc_table_name('OPS_HELPER',@year) + N' (ACC_ID, DT, REC_ID)' + char(13) +
		N'SELECT DEBIT_ID, DOC_DATE, REC_ID FROM inserted' + char(13) +
		N'UNION ALL' + char(13) +
		N'SELECT CREDIT_ID, DOC_DATE, REC_ID FROM inserted' + char(13) + char(13) +

		N'DECLARE @tbl TABLE (ACC_ID int NOT NULL PRIMARY KEY CLUSTERED, DBO money NULL, CRO money NULL)' + char(13) +
		N'DECLARE @dt smalldatetime' + char(13) +
		N'SELECT TOP 1 @dt = DOC_DATE FROM inserted' + char(13) + char(13) +

		N'INSERT INTO @tbl (ACC_ID, DBO, CRO)' + char(13) +
		N'SELECT H.ACC_ID, SUM(H.D), SUM(H.C)' + char(13) +
		N'FROM (' + char(13) +
		N'  SELECT DEBIT_ID AS ACC_ID, AMOUNT AS D, $0.0000 AS C FROM inserted' + char(13) +
		N'  UNION ALL' + char(13) +
		N'  SELECT CREDIT_ID, $0.0000, AMOUNT FROM inserted) H' + char(13) +
		N'GROUP BY H.ACC_ID' + char(13) + char(13) +
		
		N'INSERT INTO dbo.' + dbo.sys_get_arc_table_name('SALDOS',@year) + N'(ACC_ID,DT,DBO,CRO,SALDO)' + char(13) +
		N'SELECT H.ACC_ID, @dt, ISNULL(H.DBO, $0.00), ISNULL(H.CRO, $0.00), ISNULL(A.SALDO, $0.00) + ISNULL(H.DBO, $0.00) - ISNULL(H.CRO, $0.00)' + char(13) +
		N'FROM @tbl H' + char(13) +
		N'  INNER JOIN dbo.ACCOUNTS_DETAILS A ON A.ACC_ID = H.ACC_ID' + char(13) + char(13) +

		N'UPDATE dbo.ACCOUNTS_DETAILS' + char(13) +
		N'SET UID2 = UID2 + 1, SALDO = ISNULL(A.SALDO, $0.00) + ISNULL(H.DBO, $.00) - ISNULL(H.CRO, $0.00), LAST_OP_DATE = @dt' + char(13) +
		N'FROM dbo.ACCOUNTS_DETAILS A' + char(13) +
		N'  INNER JOIN @tbl H ON A.ACC_ID = H.ACC_ID'
	
	EXEC sp_executesql @sql

	SET @sql = 
		N'CREATE TRIGGER dbo.ON_' + dbo.sys_get_arc_table_name('OPS',@year) + '_DELETE' + char(13) +
		N'ON dbo.' + dbo.sys_get_arc_table_name('OPS',@year) + N' AFTER DELETE AS' + char(13) + char(13) +

		N'SET NOCOUNT ON' + char(13) + char(13) +

		N'DECLARE @tbl TABLE (ACC_ID int NOT NULL PRIMARY KEY CLUSTERED, DBO money NULL, CRO money NULL)' + char(13) +

		N'INSERT INTO @tbl (ACC_ID, DBO, CRO)' + char(13) +
		N'SELECT H.ACC_ID, SUM(H.D), SUM(H.C)' + char(13) +
		N'FROM (' + char(13) +
		N'  SELECT DEBIT_ID AS ACC_ID, AMOUNT AS D, $0.0000 AS C FROM deleted' + char(13) +
		N'  UNION ALL' + char(13) +
		N'  SELECT CREDIT_ID, $0.0000, AMOUNT FROM deleted) H' + char(13) +
		N'GROUP BY H.ACC_ID' + char(13) + char(13) +
		
		N'UPDATE dbo.ACCOUNTS_DETAILS' + char(13) +
		N'SET UID2 = UID2 + 1, SALDO = ISNULL(A.SALDO, $0.00) - ISNULL(H.DBO, $.00) + ISNULL(H.CRO, $0.00)' + char(13) +
		N'FROM dbo.ACCOUNTS_DETAILS A' + char(13) +
		N'  INNER JOIN @tbl H ON A.ACC_ID = H.ACC_ID'
	
	EXEC sp_executesql @sql
END
ELSE
BEGIN
	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT CK_OPS_AMOUNT_GT_0 CHECK (([AMOUNT] > 0))')
	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT CK_OPS_DEBIT_NE_CREDIT CHECK (([DEBIT_ID] <> [CREDIT_ID]))')

	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT
		FK_OPS_DEBIT_ID_IS_IN_ACCOUNTS FOREIGN KEY (DEBIT_ID) REFERENCES dbo.ACCOUNTS([ACC_ID]) ON UPDATE NO ACTION ON DELETE NO ACTION')
	
	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT
		FK_OPS_CREDIT_ID_IS_IN_ACCOUNTS FOREIGN KEY (CREDIT_ID) REFERENCES dbo.ACCOUNTS([ACC_ID]) ON UPDATE NO ACTION ON DELETE NO ACTION')
	
	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT
		FK_OPS_ISO_IS_IN_VAL_CODES FOREIGN KEY (ISO) REFERENCES dbo.VAL_CODES([ISO]) ON UPDATE CASCADE ON DELETE NO ACTION')

	EXEC('ALTER TABLE dbo.OPS_0000 WITH CHECK ADD CONSTRAINT
		FK_OPS_OWNER_IS_IN_USERS FOREIGN KEY (OWNER) REFERENCES dbo.USERS([USER_ID]) ON UPDATE NO ACTION ON DELETE NO ACTION')

	EXEC('ALTER TABLE dbo.OPS_0000 ADD CONSTRAINT
		DF_OPS_0000_IS_SUSPICIOUS DEFAULT 0 FOR IS_SUSPICIOUS')

	EXEC('ALTER TABLE dbo.OPS_0000 ADD CONSTRAINT
		DF_OPS_0000_UID DEFAULT 0 FOR UID')

	EXEC('ALTER TABLE dbo.OPS_0000 ADD CONSTRAINT
		DF_OPS_0000_FLAGS DEFAULT 0 FOR FLAGS')
END
GO
