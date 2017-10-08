CREATE TABLE [dbo].[DEPO_OPS]
(
[OP_ID] [int] NOT NULL IDENTITY(1, 1),
[DEPO_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[OP_NO] [int] NOT NULL CONSTRAINT [DF_DX_DEPOSIT_OPS_OP_NO] DEFAULT ((0)),
[OP_TYPE] [int] NOT NULL,
[OWN_DATA] [bit] NOT NULL,
[AMOUNT] [money] NULL,
[SELF_EXEC] [bit] NOT NULL,
[COMMIT_STATE] [tinyint] NOT NULL,
[BASIS] [text] COLLATE Latin1_General_BIN NULL,
[DOC_REC_ID] [int] NULL,
[OWNER] [int] NOT NULL,
[COMMITER_OWNER] [int] NULL,
[EXT_DATE] [smalldatetime] NULL,
[EXT_MONEY] [money] NULL,
[EXT_INT] [int] NULL,
[EXT_ACC_ID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_DEPO_OPS_INSERT_OP] ON [dbo].[DEPO_OPS]
FOR INSERT
AS

SET NOCOUNT ON

DECLARE @e int, @r int

DECLARE 
	@oid int,
	@did int,
	@dt smalldatetime

DECLARE cc CURSOR FOR
SELECT OP_ID, DEPO_ID, DT
FROM INSERTED

OPEN cc
FETCH NEXT FROM cc INTO @oid, @did, @dt

WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE dbo.DEPO_OPS
	SET OP_NO = (SELECT (ISNULL(MAX(O.OP_NO), 0) + 1) FROM dbo.DEPO_OPS O WHERE O.DEPO_ID = @did AND O.DT = @dt)
	WHERE OP_ID = @oid
	SELECT @r = @@ROWCOUNT, @e = @@ERROR
	IF @e<>0 OR @r<>1 BEGIN CLOSE cc DEALLOCATE cc ROLLBACK END

	UPDATE dbo.DEPOS SET OP_ID = @oid WHERE DEPO_ID = @did
	SELECT @r=@@ROWCOUNT, @e=@@ERROR
	IF @e<>0 OR @r<>1 BEGIN CLOSE cc DEALLOCATE cc ROLLBACK END

	FETCH NEXT FROM cc INTO @oid, @did, @dt
END
CLOSE cc
DEALLOCATE cc
RETURN
GO
ALTER TABLE [dbo].[DEPO_OPS] ADD CONSTRAINT [PK_DEPO_OPS] PRIMARY KEY CLUSTERED  ([OP_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DEPO_OPS_DEPO_ID] ON [dbo].[DEPO_OPS] ([DEPO_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_OPS] ADD CONSTRAINT [FK_DEPO_OPS_DEPO_OPS_DESCRIP] FOREIGN KEY ([OP_TYPE]) REFERENCES [dbo].[DEPO_OPS_DESCRIP] ([OP_TYPE])
GO
ALTER TABLE [dbo].[DEPO_OPS] WITH NOCHECK ADD CONSTRAINT [FK_DEPO_OPS_DEPOS_DEPO_ID] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPOS] ([DEPO_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DEPO_OPS] WITH NOCHECK ADD CONSTRAINT [FK_DEPO_OPS_USERS_COMMITER_OWNER] FOREIGN KEY ([COMMITER_OWNER]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
ALTER TABLE [dbo].[DEPO_OPS] WITH NOCHECK ADD CONSTRAINT [FK_DEPO_OPS_USERS_OWNER] FOREIGN KEY ([OWNER]) REFERENCES [dbo].[USERS] ([USER_ID])
GO