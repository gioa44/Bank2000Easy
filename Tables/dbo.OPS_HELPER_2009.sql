CREATE TABLE [dbo].[OPS_HELPER_2009]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[REC_ID] [int] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[OPS_HELPER_2009] ADD CONSTRAINT [CK_OPS_HELPER_2009] CHECK (([DT]>='20090101' AND [DT]<'20100101'))
GO
ALTER TABLE [dbo].[OPS_HELPER_2009] ADD CONSTRAINT [PK_OPS_HELPER_2009] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT], [REC_ID]) ON [ARCHIVE]
GO
CREATE NONCLUSTERED INDEX [IX_OPS_HELPER_2009] ON [dbo].[OPS_HELPER_2009] ([REC_ID]) ON [ARCHIVE]
GO
