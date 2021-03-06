CREATE TABLE [dbo].[ACCOUNTS_MIN_AMOUNTS]
(
[ACC_ID] [int] NOT NULL,
[START_DATE] [smalldatetime] NOT NULL,
[END_DATE] [smalldatetime] NULL,
[CONTRACT_END_DATE] [smalldatetime] NULL,
[AMOUNT] [money] NOT NULL,
[COMMENT] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNTS_MIN_AMOUNTS] ADD CONSTRAINT [PK_ACCOUNTS_MIN_AMOUNTS] PRIMARY KEY CLUSTERED  ([ACC_ID], [START_DATE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNTS_MIN_AMOUNTS] ADD CONSTRAINT [FK_ACCOUNTS_MIN_AMOUNTS_ACCOUNTS] FOREIGN KEY ([ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
