CREATE TABLE [dbo].[SALDOS_2017]
(
[ACC_ID] [int] NOT NULL,
[DT] [smalldatetime] NOT NULL,
[DBO] [money] NOT NULL,
[CRO] [money] NOT NULL,
[SALDO] [money] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[SALDOS_2017] ADD CONSTRAINT [CK_SALDOS_2017] CHECK (([DT]>='20170101' AND [DT]<'20170901'))
GO
ALTER TABLE [dbo].[SALDOS_2017] ADD CONSTRAINT [PK_SALDOS_2017] PRIMARY KEY CLUSTERED  ([ACC_ID], [DT]) ON [ARCHIVE]
GO