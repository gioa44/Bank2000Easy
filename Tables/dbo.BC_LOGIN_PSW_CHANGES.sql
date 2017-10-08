CREATE TABLE [dbo].[BC_LOGIN_PSW_CHANGES]
(
[BC_LOGIN_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DT_TM] [smalldatetime] NOT NULL CONSTRAINT [DF_BC_LOGIN_PSW_CHANGES_DT_TM] DEFAULT (getdate()),
[USER_ID] [int] NULL,
[CHANGED_BY_WBC_USER] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGIN_PSW_CHANGES] ADD CONSTRAINT [PK_BC_LOGIN_PSW_CHANGES] PRIMARY KEY CLUSTERED  ([BC_LOGIN_ID], [REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGIN_PSW_CHANGES] WITH NOCHECK ADD CONSTRAINT [FK_BC_LOGIN_PSW_CHANGES_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
