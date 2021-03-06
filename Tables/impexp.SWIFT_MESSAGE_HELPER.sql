CREATE TABLE [impexp].[SWIFT_MESSAGE_HELPER]
(
[DOC_REC_ID] [int] NOT NULL,
[TAG] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[OPT] [char] (1) COLLATE Latin1_General_BIN NULL,
[TAG_VALUE] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [impexp].[SWIFT_MESSAGE_HELPER] ADD CONSTRAINT [PK_SWIFT_MESSAGE_HELPER] PRIMARY KEY CLUSTERED  ([DOC_REC_ID], [TAG]) ON [PRIMARY]
GO
ALTER TABLE [impexp].[SWIFT_MESSAGE_HELPER] ADD CONSTRAINT [FK_SWIFT_MESSAGE_HELPER_DOCS_OUT_SWIFT] FOREIGN KEY ([DOC_REC_ID]) REFERENCES [impexp].[DOCS_OUT_SWIFT] ([DOC_REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
