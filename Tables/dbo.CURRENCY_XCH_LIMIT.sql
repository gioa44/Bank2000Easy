CREATE TABLE [dbo].[CURRENCY_XCH_LIMIT]
(
[ISO] [dbo].[TISO] NOT NULL,
[ISO_EQU] [dbo].[TISO] NULL,
[AMOUNT] [dbo].[TAMOUNT] NOT NULL,
[LIMIT_TIME] [smalldatetime] NULL,
[AMOUNT2] [dbo].[TAMOUNT] NULL,
[ISO_EQU2] [dbo].[TISO] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CURRENCY_XCH_LIMIT] ADD CONSTRAINT [PK_CURRENCY_XCH_LIMIT] PRIMARY KEY CLUSTERED  ([ISO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CURRENCY_XCH_LIMIT] ADD CONSTRAINT [FK_CURRENCY_XCH_LIMIT_VAL_CODES] FOREIGN KEY ([ISO]) REFERENCES [dbo].[VAL_CODES] ([ISO])
GO
ALTER TABLE [dbo].[CURRENCY_XCH_LIMIT] ADD CONSTRAINT [FK_CURRENCY_XCH_LIMIT_VAL_CODES1] FOREIGN KEY ([ISO_EQU]) REFERENCES [dbo].[VAL_CODES] ([ISO])
GO
ALTER TABLE [dbo].[CURRENCY_XCH_LIMIT] ADD CONSTRAINT [FK_CURRENCY_XCH_LIMIT_VAL_CODES2] FOREIGN KEY ([ISO_EQU2]) REFERENCES [dbo].[VAL_CODES] ([ISO])
GO
