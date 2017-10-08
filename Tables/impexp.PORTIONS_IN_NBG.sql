CREATE TABLE [impexp].[PORTIONS_IN_NBG]
(
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[STATE] [int] NOT NULL CONSTRAINT [DF_PORTIONS_RECV_STATE] DEFAULT ((0)),
[AMOUNT] [money] NOT NULL CONSTRAINT [DF_PORTIONS_RECV_AMOUNT] DEFAULT (($0.0000)),
[COUNT] [int] NOT NULL CONSTRAINT [DF_PORTIONS_RECV_COUNT] DEFAULT ((0)),
[RECV_TIME] [smalldatetime] NULL,
[FINISH_TIME] [smalldatetime] NULL,
[DOC_REC_ID] [int] NULL,
[PROCESSED_AMOUNT] [money] NOT NULL CONSTRAINT [DF_PORTIONS_IN_NBG_PRECESSED_AMOUNT] DEFAULT (($0.0000)),
[PROCESSED_COUNT] [int] NOT NULL CONSTRAINT [DF_PORTIONS_IN_NBG_PROCESSED_COUNT] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_IN_NBG] ADD CONSTRAINT [PK_PORTIONS_IN] PRIMARY KEY CLUSTERED  ([PORTION_DATE], [PORTION]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[PORTIONS_IN_NBG] ADD CONSTRAINT [FK_PORTIONS_IN_NBG_PORTION_STATES] FOREIGN KEY ([STATE]) REFERENCES [impexp].[PORTION_STATES] ([STATE]) ON UPDATE CASCADE
GO
