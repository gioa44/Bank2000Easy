CREATE TABLE [dbo].[BC_LOGIN_ACC_LIMITS]
(
[REC_ID] [int] NOT NULL,
[LIMIT_TYPE] [tinyint] NOT NULL,
[LIMIT_PERIOD] [tinyint] NOT NULL,
[LIMIT_VALUE] [dbo].[TAMOUNT] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGIN_ACC_LIMITS] WITH NOCHECK ADD CONSTRAINT [CK_BC_LOGIN_ACC_LIMITS_2] CHECK (([LIMIT_PERIOD]>=(0) AND [LIMIT_PERIOD]<=(6)))
GO
ALTER TABLE [dbo].[BC_LOGIN_ACC_LIMITS] WITH NOCHECK ADD CONSTRAINT [CK_BC_LOGIN_ACC_LIMITS_1] CHECK (([LIMIT_TYPE]=(3) OR [LIMIT_TYPE]=(2) OR [LIMIT_TYPE]=(1)))
GO
CREATE CLUSTERED INDEX [IX_BC_LOGIN_ACC_LIMITS] ON [dbo].[BC_LOGIN_ACC_LIMITS] ([REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LOGIN_ACC_LIMITS] ADD CONSTRAINT [FK_BC_LOGIN_ACC_LIMITS_BC_LOGIN_ACC] FOREIGN KEY ([REC_ID]) REFERENCES [dbo].[BC_LOGIN_ACC] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
