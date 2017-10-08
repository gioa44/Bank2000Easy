CREATE TABLE [dbo].[TMP_BALANCES_OOB]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ISO] [char] (3) COLLATE Latin1_General_BIN NOT NULL,
[DEBIT] [money] NOT NULL,
[CREDIT] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[TMP_BALANCES_OOB] ADD CONSTRAINT [PK__TMP_BALANCES_OOB__5BF7E755] PRIMARY KEY CLUSTERED  ([BAL_ACC], [ISO]) ON [PRIMARY]
GO