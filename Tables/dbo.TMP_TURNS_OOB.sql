CREATE TABLE [dbo].[TMP_TURNS_OOB]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ISO] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[DEBIT] [money] NOT NULL,
[CREDIT] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMP_TURNS_OOB] ADD CONSTRAINT [PK__TMP_TURNS_OOB__5ED45400] PRIMARY KEY CLUSTERED  ([BAL_ACC], [ISO]) ON [PRIMARY]
GO