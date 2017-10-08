CREATE TABLE [dbo].[TMP_TURNS]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ISO] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[DEBIT] [money] NOT NULL,
[CREDIT] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMP_TURNS] ADD CONSTRAINT [PK__TMP_TURNS__0AB2D63E] PRIMARY KEY CLUSTERED  ([BAL_ACC], [ISO]) ON [PRIMARY]
GO