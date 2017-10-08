CREATE TABLE [dbo].[SALDOS_2015]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[DBO] [money] NOT NULL,
[CRO] [money] NOT NULL,
[SALDO] [money] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[SALDOS_2015] ADD CONSTRAINT [CK_SALDOS_2015] CHECK (([DT]>='20150101' AND [DT]<'20160101'))
GO
ALTER TABLE [dbo].[SALDOS_2015] ADD CONSTRAINT [PK_SALDOS_2015] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT]) ON [ARCHIVE]
GO