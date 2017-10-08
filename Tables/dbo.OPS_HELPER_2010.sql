CREATE TABLE [dbo].[OPS_HELPER_2010]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[REC_ID] [int] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[OPS_HELPER_2010] ADD CONSTRAINT [CK_OPS_HELPER_2010] CHECK (([DT]>='20100101' AND [DT]<'20110101'))
GO
ALTER TABLE [dbo].[OPS_HELPER_2010] ADD CONSTRAINT [PK_OPS_HELPER_2010] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT], [REC_ID]) ON [ARCHIVE]
GO