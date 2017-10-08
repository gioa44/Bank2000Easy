CREATE TABLE [dbo].[LOAN_INSTALLMENT_EVENT_ITEMS]
(
[LOAN_ID] [int] NOT NULL,
[ITEM_ID] [int] NOT NULL,
[DESCRIP] [dbo].[TDESCRIP] NOT NULL,
[DESCRIP_LAT] [dbo].[TDESCRIP] NULL,
[ITEM_PRICE] [money] NOT NULL
) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LOAN_INSTALLMENT_EVENT_ITEMS_1] ON [dbo].[LOAN_INSTALLMENT_EVENT_ITEMS] ([ITEM_ID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_LOAN_INSTALLMENT_EVENT_ITEMS] ON [dbo].[LOAN_INSTALLMENT_EVENT_ITEMS] ([LOAN_ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[LOAN_INSTALLMENT_EVENT_ITEMS] ADD CONSTRAINT [FK_LOAN_INSTALLMENT_EVENT_ITEMS_LOAN_INSTALLMENT_EVENTS] FOREIGN KEY ([ITEM_ID]) REFERENCES [dbo].[LOAN_INSTALLMENT_EVENTS] ([ITEM_ID])
GO
ALTER TABLE [dbo].[LOAN_INSTALLMENT_EVENT_ITEMS] ADD CONSTRAINT [FK_LOAN_INSTALLMENT_EVENT_ITEMS_LOAN_INSTALLMENTS] FOREIGN KEY ([LOAN_ID]) REFERENCES [dbo].[LOAN_INSTALLMENTS] ([LOAN_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
