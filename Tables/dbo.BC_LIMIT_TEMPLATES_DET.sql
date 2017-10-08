CREATE TABLE [dbo].[BC_LIMIT_TEMPLATES_DET]
(
[REC_ID] [int] NOT NULL,
[LIMIT_TYPE] [tinyint] NOT NULL,
[LIMIT_PERIOD] [tinyint] NOT NULL,
[LIMIT_VALUE] [dbo].[TAMOUNT] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LIMIT_TEMPLATES_DET] WITH NOCHECK ADD CONSTRAINT [CK_BC_LIMIT_TEMPLATES_DET_2] CHECK (([LIMIT_PERIOD]>=(0) AND [LIMIT_PERIOD]<=(6)))
GO
ALTER TABLE [dbo].[BC_LIMIT_TEMPLATES_DET] WITH NOCHECK ADD CONSTRAINT [CK_BC_LIMIT_TEMPLATES_DET_1] CHECK (([LIMIT_TYPE]=(3) OR [LIMIT_TYPE]=(2) OR [LIMIT_TYPE]=(1)))
GO
CREATE CLUSTERED INDEX [IX_BC_LIMIT_TEMPLATES_DET] ON [dbo].[BC_LIMIT_TEMPLATES_DET] ([REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[BC_LIMIT_TEMPLATES_DET] WITH NOCHECK ADD CONSTRAINT [FK_BC_LIMIT_TEMPLATES_DET_BC_LIMIT_TEMPLATES] FOREIGN KEY ([REC_ID]) REFERENCES [dbo].[BC_LIMIT_TEMPLATES] ([REC_ID])
GO
