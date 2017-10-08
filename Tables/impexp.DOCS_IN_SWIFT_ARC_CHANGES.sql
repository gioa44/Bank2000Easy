CREATE TABLE [impexp].[DOCS_IN_SWIFT_ARC_CHANGES]
(
[PORTION_DATE] [smalldatetime] NOT NULL,
[PORTION] [int] NOT NULL,
[ROW_ID] [int] NOT NULL,
[REC_ID] [int] NOT NULL,
[USER_ID] [int] NOT NULL,
[DATE_TIME] [datetime] NOT NULL CONSTRAINT [DF_DOCS_IN_SWIFT_ARC_CHANGES_DATE_TIME] DEFAULT (getdate()),
[CHANGE_TYPE] [int] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[DOCS_IN_SWIFT_ARC_CHANGES] ADD CONSTRAINT [PK_DOCS_IN_SWIFT_ARC_CHANGES] PRIMARY KEY CLUSTERED  ([PORTION_DATE], [PORTION], [ROW_ID], [REC_ID]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[DOCS_IN_SWIFT_ARC_CHANGES] ADD CONSTRAINT [FK_DOCS_IN_SWIFT_ARC_CHANGES_DOCS_IN_SWIFT_ARC] FOREIGN KEY ([PORTION_DATE], [PORTION], [ROW_ID]) REFERENCES [impexp].[DOCS_IN_SWIFT_ARC] ([PORTION_DATE], [PORTION], [ROW_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [impexp].[DOCS_IN_SWIFT_ARC_CHANGES] ADD CONSTRAINT [FK_DOCS_IN_SWIFT_ARC_CHANGES_USERS] FOREIGN KEY ([USER_ID]) REFERENCES [dbo].[USERS] ([USER_ID])
GO
