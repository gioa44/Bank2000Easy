CREATE TABLE [easy].[OverduePercentsOn912Report]
(
[RecordId] [int] NOT NULL IDENTITY(1, 1),
[Dec2012Balance] [money] NOT NULL,
[TodayBalance] [money] NOT NULL,
[Diff] [money] NOT NULL,
[BalanceToReturn] [money] NOT NULL,
[Iso] [dbo].[TISO] NOT NULL,
[LoanId] [int] NOT NULL,
[AgreementNo] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[CurrentOverdueDate] [smalldatetime] NULL,
[Exists In LoanDetails] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [easy].[OverduePercentsOn912Report] ADD CONSTRAINT [PK__OverdueP__FBDF78E948D789BC] PRIMARY KEY CLUSTERED  ([RecordId]) ON [PRIMARY]
GO
