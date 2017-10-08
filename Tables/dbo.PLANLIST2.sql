CREATE TABLE [dbo].[PLANLIST2]
(
[BAL_ACC] [dbo].[TBAL_ACC] NOT NULL,
[ACT_PAS] [tinyint] NOT NULL,
[CLASS_TYPE] [tinyint] NOT NULL,
[VAL_TYPE] [tinyint] NOT NULL,
[REC_STATE] [tinyint] NULL CONSTRAINT [DF_PLANLIST2_REC_STATE] DEFAULT ((0)),
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[DESCRIP_LAT] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[ACC_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_PLANLIST2_ACC_TYPE] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[PLANLIST2] ADD CONSTRAINT [CK_PLANLIST2_4] CHECK (([ACC_TYPE]=(2) OR [ACC_TYPE]=(1) OR [ACC_TYPE]=(0)))
GO
ALTER TABLE [dbo].[PLANLIST2] ADD CONSTRAINT [CK_PLANLIST2_1] CHECK (([ACT_PAS]>=(0) AND [ACT_PAS]<=(2)))
GO
ALTER TABLE [dbo].[PLANLIST2] ADD CONSTRAINT [CK_PLANLIST2_2] CHECK (([CLASS_TYPE]=(64) OR [CLASS_TYPE]=(32) OR [CLASS_TYPE]=(16) OR [CLASS_TYPE]=(8) OR [CLASS_TYPE]=(4) OR [CLASS_TYPE]=(2) OR [CLASS_TYPE]=(1)))
GO
ALTER TABLE [dbo].[PLANLIST2] ADD CONSTRAINT [CK_PLANLIST2_3] CHECK (([VAL_TYPE]=(4) OR [VAL_TYPE]=(2) OR [VAL_TYPE]=(1)))
GO
ALTER TABLE [dbo].[PLANLIST2] ADD CONSTRAINT [PK_PLANLIST2] PRIMARY KEY CLUSTERED  ([BAL_ACC]) ON [PRIMARY]
GO
