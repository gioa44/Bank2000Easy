CREATE TABLE [dbo].[OPS_2012]
(
[REC_ID] [int] NOT NULL,
[UID] [int] NOT NULL,
[DOC_DATE] [smalldatetime] NOT NULL,
[DOC_DATE_IN_DOC] [smalldatetime] NULL,
[ISO] [dbo].[TISO] NOT NULL,
[AMOUNT] [money] NOT NULL,
[AMOUNT_EQU] [money] NOT NULL,
[DOC_NUM] [int] NULL,
[OP_CODE] [dbo].[TOPCODE] NULL,
[DEBIT_ID] [int] NOT NULL,
[CREDIT_ID] [int] NOT NULL,
[REC_STATE] [tinyint] NOT NULL,
[BNK_CLI_ID] [int] NULL,
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NULL,
[PARENT_REC_ID] [int] NULL,
[OWNER] [int] NOT NULL,
[DOC_TYPE] [smallint] NOT NULL,
[ACCOUNT_EXTRA] [dbo].[TACCOUNT] NULL,
[PROD_ID] [int] NULL,
[FOREIGN_ID] [int] NULL,
[CHANNEL_ID] [int] NULL,
[DEPT_NO] [int] NULL,
[IS_SUSPICIOUS] [bit] NOT NULL,
[CASHIER] [int] NULL,
[CHK_SERIE] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[CASH_AMOUNT] [money] NULL,
[TREASURY_CODE] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[TAX_CODE_OR_PID] [varchar] (11) COLLATE Latin1_General_BIN NULL,
[RELATION_ID] [int] NULL,
[FLAGS] [int] NOT NULL CONSTRAINT [DF_OPS_2012_FLAGS] DEFAULT ((0)),
[BRANCH_ID] [int] NULL
) ON [ARCHIVE]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_OPS_2012_DELETE]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[ON_OPS_2012_INSERT]
GO
ALTER TABLE [dbo].[OPS_2012] ADD CONSTRAINT [CK_OPS_2012] CHECK (([DOC_DATE]>='20120101' AND [DOC_DATE]<'20130101'))
GO
ALTER TABLE [dbo].[OPS_2012] ADD CONSTRAINT [PK_OPS_2012] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_ACC_EXTRA] ON [dbo].[OPS_2012] ([ACCOUNT_EXTRA]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_DT] ON [dbo].[OPS_2012] ([DOC_DATE]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_DOC_TYPE] ON [dbo].[OPS_2012] ([DOC_TYPE]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_ISO] ON [dbo].[OPS_2012] ([ISO]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_OWNER] ON [dbo].[OPS_2012] ([OWNER]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_2012_PARENT_REC_ID] ON [dbo].[OPS_2012] ([PARENT_REC_ID]) ON [ARCHIVE]
GO