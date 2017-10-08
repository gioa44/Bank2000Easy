CREATE TABLE [dbo].[BAL_2013]
(
[DT] [smalldatetime] NOT NULL,
[BRANCH_ID] [int] NOT NULL,
[DEPT_NO] [int] NOT NULL,
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ISO] [dbo].[TISO] NOT NULL,
[DBO] [money] NOT NULL,
[DBO_EQU] [money] NOT NULL,
[CRO] [money] NOT NULL,
[CRO_EQU] [money] NOT NULL,
[DBS] [money] NOT NULL,
[DBS_EQU] [money] NOT NULL,
[CRS] [money] NOT NULL,
[CRS_EQU] [money] NOT NULL
) ON [ARCHIVE]
GO
ALTER TABLE [dbo].[BAL_2013] ADD CONSTRAINT [CK_BAL_2013] CHECK (([DT]>='20130101' AND [DT]<'20140101'))
GO
ALTER TABLE [dbo].[BAL_2013] ADD CONSTRAINT [PK_BAL_2013] PRIMARY KEY CLUSTERED  ([DT], [BRANCH_ID], [DEPT_NO], [BAL_ACC], [ISO]) ON [ARCHIVE]
GO
