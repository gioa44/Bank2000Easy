CREATE TABLE [dbo].[ACCOUNTS_USR]
(
[USER_ID] [int] NOT NULL,
[ACC_ID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNTS_USR] ADD CONSTRAINT [PK_ACCOUNTS_USR] PRIMARY KEY CLUSTERED  ([USER_ID], [ACC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACCOUNTS_USR] ADD CONSTRAINT [FK_ACCOUNTS_USR_ACCOUNTS] FOREIGN KEY ([ACC_ID]) REFERENCES [dbo].[ACCOUNTS] ([ACC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[ACCOUNTS_USR] ADD CONSTRAINT [FK_ACCOUNTS_USR_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
