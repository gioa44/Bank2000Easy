CREATE TABLE [dbo].[DEPO_SCHEDULE_ARC]
(
[OP_ID] [int] NOT NULL,
[DEPO_ID] [int] NOT NULL,
[SCHEDULE_DATE] [smalldatetime] NOT NULL,
[PAYMENT] [money] NOT NULL,
[PRINCIPAL] [money] NOT NULL,
[INTEREST] [money] NOT NULL,
[INTEREST_TAX] [money] NOT NULL,
[TAX] [money] NOT NULL,
[BALANCE] [money] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_SCHEDULE_ARC] ADD CONSTRAINT [PK_DEPO_SCHEDULE_ARC] PRIMARY KEY CLUSTERED  ([OP_ID], [DEPO_ID], [SCHEDULE_DATE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DEPO_SCHEDULE_ARC] ADD CONSTRAINT [FK_DEPO_SCHEDULE_ARC_DEPO_DEPOSITS] FOREIGN KEY ([DEPO_ID]) REFERENCES [dbo].[DEPO_DEPOSITS] ([DEPO_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
