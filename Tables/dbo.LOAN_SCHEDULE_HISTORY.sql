CREATE TABLE [dbo].[LOAN_SCHEDULE_HISTORY]
(
[LOAN_ID] [int] NOT NULL,
[OP_ID] [int] NOT NULL,
[SCHEDULE_DATE] [smalldatetime] NOT NULL,
[INTEREST_DATE] [smalldatetime] NOT NULL,
[AMOUNT] [money] NULL,
[PRINCIPAL] [money] NULL,
[INTEREST] [money] NULL,
[NU_INTEREST] [money] NULL,
[BALANCE] [money] NULL,
[PAY_INTEREST] [bit] NULL,
[INTEREST_CORRECTION] [money] NULL,
[NU_INTEREST_CORRECTION] [money] NULL,
[ORIGINAL_AMOUNT] [money] NULL,
[ORIGINAL_PRINCIPAL] [money] NULL,
[ORIGINAL_INTEREST] [money] NULL,
[ORIGINAL_NU_INTEREST] [money] NULL,
[ORIGINAL_BALANCE] [money] NULL,
[INSURANCE] [money] NULL,
[SERVICE_FEE] [money] NULL,
[ORIGINAL_INSURANCE] [money] NULL,
[ORIGINAL_SERVICE_FEE] [money] NULL,
[DEFERED_INTEREST] [money] NULL,
[DEFERED_OVERDUE_INTEREST] [money] NULL,
[DEFERED_PENALTY] [money] NULL,
[DEFERED_FINE] [money] NULL,
[ORIGINAL_DEFERED_INTEREST] [money] NULL,
[ORIGINAL_DEFERED_OVERDUE_INTEREST] [money] NULL,
[ORIGINAL_DEFERED_PENALTY] [money] NULL,
[ORIGINAL_DEFERED_FINE] [money] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_SCHEDULE_HISTORY] ADD CONSTRAINT [PK_LOAN_SCHEDULE_HISTORY] PRIMARY KEY CLUSTERED  ([LOAN_ID], [OP_ID], [SCHEDULE_DATE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_SCHEDULE_HISTORY] ADD CONSTRAINT [FK_LOAN_SCHEDULE_HISTORY_LOAN_OPS] FOREIGN KEY ([OP_ID]) REFERENCES [dbo].[LOAN_OPS] ([OP_ID]) ON DELETE CASCADE
GO