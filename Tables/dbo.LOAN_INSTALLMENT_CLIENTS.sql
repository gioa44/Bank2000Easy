CREATE TABLE [dbo].[LOAN_INSTALLMENT_CLIENTS]
(
[CLIENT_NO] [int] NOT NULL,
[INTEREST_TYPE] [tinyint] NOT NULL,
[STEP_COUNT] [tinyint] NULL,
[INTRATE] [money] NULL,
[IS_ACTIVE] [bit] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_INSTALLMENT_CLIENTS] ADD CONSTRAINT [CK_LOAN_INSTALLMENT_CLIENTS] CHECK (([INTEREST_TYPE]=(2) OR [INTEREST_TYPE]=(1) OR [INTEREST_TYPE]=(0)))
GO
ALTER TABLE [dbo].[LOAN_INSTALLMENT_CLIENTS] ADD CONSTRAINT [PK_LOAN_INSTALLMENT_CLIENTS] PRIMARY KEY CLUSTERED  ([CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_INSTALLMENT_CLIENTS] ADD CONSTRAINT [FK_LOAN_INSTALLMENT_CLIENTS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO])
GO