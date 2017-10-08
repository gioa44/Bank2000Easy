CREATE TABLE [dbo].[VAL_RATES_2012]
(
[ISO] [dbo].[TISO] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[ITEMS] [int] NOT NULL,
[AMOUNT] [money] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[VAL_RATES_2012] ADD CONSTRAINT [CK_VAL_RATES_2012] CHECK (([DT]>='20120101' AND [DT]<'20130101'))
GO
ALTER TABLE [dbo].[VAL_RATES_2012] ADD CONSTRAINT [PK_VAL_RATES_2012] PRIMARY KEY CLUSTERED  ([ISO], [DT]) ON [ARCHIVE]
GO