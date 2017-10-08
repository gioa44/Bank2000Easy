CREATE TABLE [dbo].[LOAN_OVERDUE_DELAY]
(
[LOAN_ID] [int] NOT NULL,
[DELAY_DATE] [smalldatetime] NOT NULL,
[USER_ID] [int] NOT NULL,
[DELAY_REASON] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_OVERDUE_DELAY] ADD CONSTRAINT [PK_LOAN_OVERDUE_DELAY] PRIMARY KEY CLUSTERED  ([LOAN_ID], [DELAY_DATE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_OVERDUE_DELAY] ADD CONSTRAINT [FK_LOAN_OVERDUE_DELAY_LOANS] FOREIGN KEY ([LOAN_ID]) REFERENCES [dbo].[LOANS] ([LOAN_ID]) ON DELETE CASCADE
GO
ALTER TABLE [dbo].[LOAN_OVERDUE_DELAY] ADD CONSTRAINT [FK_LOAN_OVERDUE_DELAY_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
