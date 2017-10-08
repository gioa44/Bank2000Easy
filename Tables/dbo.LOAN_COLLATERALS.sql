CREATE TABLE [dbo].[LOAN_COLLATERALS]
(
[COLLATERAL_ID] [int] NOT NULL IDENTITY(1, 1),
[ROW_VERSION] [int] NOT NULL,
[LOAN_ID] [int] NULL,
[CREDIT_LINE_ID] [int] NULL,
[CLIENT_NO] [int] NOT NULL,
[OWNER] [int] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[COLLATERAL_TYPE] [int] NOT NULL,
[AMOUNT] [money] NOT NULL,
[DESCRIP] [varchar] (2000) COLLATE Latin1_General_BIN NULL,
[MARKET_AMOUNT] [money] NOT NULL CONSTRAINT [DF_LOAN_COLLATERALS_MARKET_AMOUNT] DEFAULT ((0)),
[COLLATERAL_DETAILS] [xml] NULL,
[IS_ENSURED] [bit] NULL,
[ENSURANCE_PAYMENT_AMOUNT] [money] NULL,
[ENSUR_PAYMENT_INTERVAL_TYPE] [int] NULL,
[ENSURANCE_COMPANY_ID] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_COLLATERALS] ADD CONSTRAINT [PK_LOAN_COLLATERALS] PRIMARY KEY CLUSTERED  ([COLLATERAL_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LOAN_COLLATERALS_CREDIT_LINE_ID] ON [dbo].[LOAN_COLLATERALS] ([CREDIT_LINE_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LOAN_COLLATERALS_LOAN_ID] ON [dbo].[LOAN_COLLATERALS] ([LOAN_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_COLLATERALS] ADD CONSTRAINT [FK_LOAN_COLLATERALS_LOAN_INSURANCE_COMPANIES] FOREIGN KEY ([ENSURANCE_COMPANY_ID]) REFERENCES [dbo].[LOAN_INSURANCE_COMPANIES] ([COMPANY_ID])
GO
ALTER TABLE [dbo].[LOAN_COLLATERALS] ADD CONSTRAINT [FK_LOAN_COLLATERALS_LOAN_PAYMENT_INTERVALS] FOREIGN KEY ([ENSUR_PAYMENT_INTERVAL_TYPE]) REFERENCES [dbo].[LOAN_PAYMENT_INTERVALS] ([TYPE_ID])
GO
