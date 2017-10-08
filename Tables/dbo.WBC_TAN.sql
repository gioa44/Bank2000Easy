CREATE TABLE [dbo].[WBC_TAN]
(
[BC_LOGIN_ID] [int] NOT NULL,
[TAN] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[TAN_ID] [int] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WBC_TAN] ADD CONSTRAINT [PK_WBC_TAN] PRIMARY KEY CLUSTERED  ([BC_LOGIN_ID], [TAN]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[WBC_TAN] WITH NOCHECK ADD CONSTRAINT [FK_WBC_TAN_BC_LOGINS] FOREIGN KEY ([BC_LOGIN_ID]) REFERENCES [dbo].[BC_LOGINS] ([BC_LOGIN_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO