CREATE TABLE [dbo].[DEPO_OP]
(
[OP_ID] [int] NOT NULL IDENTITY(1, 1),
[DEPO_ID] [int] NOT NULL,
[OP_DATE] [smalldatetime] NOT NULL,
[OP_TYPE] [smallint] NOT NULL,
[OP_STATE] [bit] NOT NULL,
[OP_TIME] [datetime] NOT NULL CONSTRAINT [DF_DEPO_OP_OP_TIME] DEFAULT (getdate()),
[AMOUNT] [money] NULL,
[ISO] [dbo].[TISO] NULL,
[OP_DATA] [xml] NULL,
[OP_ACC_DATA] [xml] NULL,
[OP_NOTE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[BY_PROCESSING] [bit] NOT NULL CONSTRAINT [DF_DEPO_OP_BY_PROCESSING] DEFAULT ((0)),
[ALARM_NOTE] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[OWNER] [int] NOT NULL,
[DOC_REC_ID] [int] NULL,
[ACCRUE_DOC_REC_ID] [int] NULL,
[AUTH_OWNER] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [PK_DEPO_OP] PRIMARY KEY CLUSTERED  ([OP_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DEPO_OP_DATE] ON [dbo].[DEPO_OP] ([OP_DATE]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_DEPO_OP_TYPE] ON [dbo].[DEPO_OP] ([OP_TYPE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [FK_DEPO_OP_DEPO_DEPOSITS] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPO_DEPOSITS] ([DEPO_ID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [FK_DEPO_OP_DEPO_OP_TYPES] FOREIGN KEY ([OP_TYPE]) REFERENCES [dbo].[DEPO_OP_TYPES] ([TYPE_ID])
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [FK_DEPO_OP_USERS_AUTH_OWNER] FOREIGN KEY ([AUTH_OWNER]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [FK_DEPO_OP_USERS_OWNER] FOREIGN KEY ([OWNER]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
ALTER TABLE [dbo].[DEPO_OP] ADD CONSTRAINT [FK_DEPO_OP_VAL_CODES] FOREIGN KEY ([ISO]) REFERENCES [dbo].[VAL_CODES] ([ISO])
GO