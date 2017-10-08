CREATE TABLE [impexp].[PORTIONS_OUT_NBG_ARC]
(
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[STATE] [int] NOT NULL,
[AMOUNT] [money] NOT NULL,
[COUNT] [int] NOT NULL,
[CREATION_TIME] [smalldatetime] NULL,
[CLOSE_TIME] [smalldatetime] NULL,
[EXPORT_TIME] [smalldatetime] NULL,
[FINISH_TIME] [smalldatetime] NULL,
[DOC_REC_ID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_OUT_NBG_ARC] ADD CONSTRAINT [PK_PORTIONS_OUT_NBG_ARC] PRIMARY KEY CLUSTERED  ([PORTION_DATE], [PORTION]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_OUT_NBG_ARC] ADD CONSTRAINT [FK_PORTIONS_OUT_NBG_ARC_PORTION_STATES] FOREIGN KEY ([STATE]) REFERENCES [impexp].[PORTION_STATES] ([STATE]) ON UPDATE CASCADE
GO
