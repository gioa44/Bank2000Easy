CREATE TABLE [dbo].[TCD_USERS]
(
[TCD_SERIAL_ID] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[USER_ID] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TCD_USERS] ADD CONSTRAINT [PK_TCD_USERS] PRIMARY KEY CLUSTERED  ([TCD_SERIAL_ID], [USER_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TCD_USERS] ADD CONSTRAINT [FK_TCD_USERS_TCDS] FOREIGN KEY ([TCD_SERIAL_ID]) REFERENCES [dbo].[TCDS] ([TCD_SERIAL_ID])
GO
ALTER TABLE [dbo].[TCD_USERS] ADD CONSTRAINT [FK_TCD_USERS_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
