CREATE TABLE [dbo].[SALDOS_2011]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[DBO] [money] NOT NULL,
[CRO] [money] NOT NULL,
[SALDO] [money] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[SALDOS_2011] ADD CONSTRAINT [CK_SALDOS_2011] CHECK (([DT]>='20110101' AND [DT]<'20120101'))
GO
ALTER TABLE [dbo].[SALDOS_2011] ADD CONSTRAINT [PK_SALDOS_2011] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT]) ON [ARCHIVE]
GO
