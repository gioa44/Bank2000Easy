CREATE TABLE [dbo].[LOAN_CREDIT_LINE_COBORROWERS]
(
[CREDIT_LINE_ID] [int] NOT NULL,
[CLIENT_NO] [int] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_COBORROWERS] ADD CONSTRAINT [PK_LOAN_CREDIT_LINE_COBORROWERS] PRIMARY KEY CLUSTERED  ([CREDIT_LINE_ID], [CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_COBORROWERS] ADD CONSTRAINT [FK_LOAN_CREDIT_LINE_COBORROWERS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[LOAN_CREDIT_LINE_COBORROWERS] ADD CONSTRAINT [FK_LOAN_CREDIT_LINE_COBORROWERS_LOAN_CREDIT_LINES] FOREIGN KEY ([CREDIT_LINE_ID]) REFERENCES [dbo].[LOAN_CREDIT_LINES] ([CREDIT_LINE_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
