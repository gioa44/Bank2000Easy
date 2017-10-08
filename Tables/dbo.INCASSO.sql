CREATE TABLE [dbo].[INCASSO]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[BRANCH_ID] [int] NOT NULL,
[CLIENT_NO] [int] NOT NULL,
[INCASSO_NUM] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[ISSUE_DATE] [smalldatetime] NOT NULL,
[REC_DATE_TIME] [datetime] NOT NULL,
[ACTIVATION_DATE_TIME] [smalldatetime] NOT NULL,
[REC_STATE] [tinyint] NOT NULL CONSTRAINT [DF_INCASSO_REC_STATE] DEFAULT ((0)),
[ACC_ID] [int] NOT NULL,
[ACC_ID_OFB] [int] NULL,
[INCASSO_AMOUNT] [money] NOT NULL,
[BALANCE] [money] NOT NULL CONSTRAINT [DF_INCASSO_BALANCE] DEFAULT (($0.0000)),
[PAYED_AMOUNT] [money] NOT NULL CONSTRAINT [DF_INCASSO_PAYED_AMOUNT] DEFAULT (($0.0000)),
[SUSPENDED_AMOUNT] [money] NOT NULL CONSTRAINT [DF_INCASSO_SUSPENDED_AMOUNT] DEFAULT (($0.0000)),
[PAYED_COUNT] [smallint] NOT NULL CONSTRAINT [DF_INCASSO_DOC_ORDER_NUM] DEFAULT ((0)),
[RECEIVER_BANK_CODE] [dbo].[TINTBANKCODE] NOT NULL,
[RECEIVER_BANK_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_ACC] [varchar] (34) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_ACC_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[RECEIVER_TAX_CODE] [varchar] (11) COLLATE Latin1_General_BIN NOT NULL,
[SAXAZKOD] [varchar] (9) COLLATE Latin1_General_BIN NULL,
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[INCASSO_ISSUER] [tinyint] NOT NULL,
[USER_ID] [int] NOT NULL,
[PENDING] [bit] NOT NULL CONSTRAINT [DF_INCASSO_PENDING] DEFAULT ((0)),
[ISO] [dbo].[TISO] NOT NULL CONSTRAINT [DF_INCASSO_ISO] DEFAULT ('GEL')
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[INCASSO] ADD CONSTRAINT [PK_INCASSO] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
EXEC sp_addextendedproperty N'MS_Description', N'ანგარიშსწორების ანგარიში', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'ACC_ID'
GO
EXEC sp_addextendedproperty N'MS_Description', N'გარებალანსური ანგარიში', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'ACC_ID_OFB'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ინკასოს აქტივაციის თარიღი და დრო', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'ACTIVATION_DATE_TIME'
GO
EXEC sp_addextendedproperty N'MS_Description', N'დარჩენილი თანხა (ნაშთი გარებალანსზე)', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'BALANCE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ინკასოს თანხა', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'INCASSO_AMOUNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ინკასოს გამოწერის თარიღი', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'ISSUE_DATE'
GO
EXEC sp_addextendedproperty N'MS_Description', N'გადახდილი თანხა', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'PAYED_AMOUNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'გადახდების რაოდენობა', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'PAYED_COUNT'
GO
EXEC sp_addextendedproperty N'MS_Description', N'ინკასოს მიღების თარიღი', 'SCHEMA', N'dbo', 'TABLE', N'INCASSO', 'COLUMN', N'REC_DATE_TIME'
GO
