CREATE TABLE [impexp].[PORTIONS_OUT_NBG]
(
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[STATE] [int] NOT NULL CONSTRAINT [DF_PORTIONS_OUT_NBG_STATE] DEFAULT ((0)),
[AMOUNT] [money] NOT NULL CONSTRAINT [DF_PORTIONS_OUT_NBG_AMOUNT] DEFAULT (($0.0000)),
[COUNT] [int] NOT NULL CONSTRAINT [DF_PORTIONS_OUT_NBG_COUNT] DEFAULT ((0)),
[CREATION_TIME] [smalldatetime] NULL CONSTRAINT [DF_PORTIONS_OUT_NBG_CREATION_TIME] DEFAULT (getdate()),
[CLOSE_TIME] [smalldatetime] NULL,
[EXPORT_TIME] [smalldatetime] NULL,
[FINISH_TIME] [smalldatetime] NULL,
[DOC_REC_ID] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_OUT_NBG] ADD CONSTRAINT [PK_PORTIONS_OUT_NBG] PRIMARY KEY CLUSTERED  ([PORTION_DATE], [PORTION]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_OUT_NBG] ADD CONSTRAINT [FK_PORTIONS_OUT_NBG_PORTION_STATES] FOREIGN KEY ([STATE]) REFERENCES [impexp].[PORTION_STATES] ([STATE]) ON UPDATE CASCADE
GO
