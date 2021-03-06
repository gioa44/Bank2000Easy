CREATE TABLE [dbo].[LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES]
(
[COLLATERAL_TYPE] [int] NOT NULL,
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[TEMPLATE] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES] ADD CONSTRAINT [PK_LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES] PRIMARY KEY CLUSTERED  ([COLLATERAL_TYPE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES] ADD CONSTRAINT [FK_LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES_LOAN_COLLATERAL_TYPES] FOREIGN KEY ([COLLATERAL_TYPE]) REFERENCES [dbo].[LOAN_COLLATERAL_TYPES] ([TYPE_ID])
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES] ADD CONSTRAINT [FK_LOAN_CREDIT_LINE_ACCOUNT_TEMPLATES_PLANLIST_ALT] FOREIGN KEY ([BAL_ACC]) REFERENCES [dbo].[PLANLIST_ALT] ([BAL_ACC])
GO
