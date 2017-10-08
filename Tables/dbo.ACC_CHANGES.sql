CREATE TABLE [dbo].[ACC_CHANGES]
(
[ACC_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[USER_ID] [int] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NULL,
[TIME_OF_CHANGE] [smalldatetime] NULL CONSTRAINT [DF_ACC_CHANGE_TIME_OF_CHANGE] DEFAULT (getdate())
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_CHANGES] ADD CONSTRAINT [PK_ACC_CHANGES] PRIMARY KEY CLUSTERED  ([ACC_ID], [REC_ID]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_ACC_CHANGES] ON [dbo].[ACC_CHANGES] ([REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_CHANGES] ADD CONSTRAINT [FK_ACC_CHANGES_ACCOUNTS] FOREIGN KEY ([ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[ACC_CHANGES] ADD CONSTRAINT [FK_ACC_CHANGES_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID]) ON UPDATE CASCADE
GO