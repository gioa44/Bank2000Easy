CREATE TABLE [easy].[EffectiveRates]
(
[LOAN_ID] [int] NOT NULL,
[OP_ID] [int] NOT NULL,
[CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIPTION] [nvarchar] (512) COLLATE Latin1_General_BIN NULL,
[RATE] [decimal] (20, 8) NULL,
[CASH_FLOW] [xml] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE CLUSTERED INDEX [CIX_EffectiveRates_LoanId] ON [easy].[EffectiveRates] ([LOAN_ID]) ON [PRIMARY]
GO
