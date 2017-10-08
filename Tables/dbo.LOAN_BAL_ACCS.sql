CREATE TABLE [dbo].[LOAN_BAL_ACCS]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[TYPE_ID] [int] NOT NULL,
[ACCOUNT_BAL_ACC] [dbo].[TBAL_ACC] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_BAL_ACCS] ADD CONSTRAINT [PK_LOAN_BAL_ACCS] PRIMARY KEY CLUSTERED  ([BAL_ACC], [TYPE_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_BAL_ACCS] ADD CONSTRAINT [FK_LOAN_BAL_ACCS_LOAN_ACCOUNT_TYPES] FOREIGN KEY ([TYPE_ID]) REFERENCES [dbo].[LOAN_ACCOUNT_TYPES] ([TYPE_ID])
GO
ALTER TABLE [dbo].[LOAN_BAL_ACCS] ADD CONSTRAINT [FK_LOAN_BAL_ACCS_PLANLIST_ALT] FOREIGN KEY ([BAL_ACC]) REFERENCES [dbo].[PLANLIST_ALT] ([BAL_ACC])
GO
