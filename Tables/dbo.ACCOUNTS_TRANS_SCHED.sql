CREATE TABLE [dbo].[ACCOUNTS_TRANS_SCHED]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DEBIT] [dbo].[TACCOUNT] NOT NULL,
[CREDIT] [dbo].[TACCOUNT] NOT NULL,
[OP_CODE] [dbo].[TOPCODE] NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[FORMULA] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNTS_TRANS_SCHED] ADD CONSTRAINT [PK_ACCOUNTS_TRANS_SCHED] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT], [REC_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_ACCOUNTS_TRANS_SCHED_DT] ON [dbo].[ACCOUNTS_TRANS_SCHED] ([DT]) ON [PRIMARY]
GO
