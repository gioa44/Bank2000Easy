CREATE TABLE [dbo].[DOC_ATTRIBUTES_ARC]
(
[REC_ID] [int] NOT NULL,
[ATTRIB_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ATTRIB_VALUE] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_ATTRIBUTES_ARC] ADD CONSTRAINT [PK_DOC_ATTRIBUTES_ARC] PRIMARY KEY CLUSTERED  ([REC_ID], [ATTRIB_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_ATTRIBUTES_ARC] ADD CONSTRAINT [FK_DOC_ATTRIBUTES_ARC_DOC_ATTRIB_CODES] FOREIGN KEY ([ATTRIB_CODE]) REFERENCES [dbo].[DOC_ATTRIB_CODES] ([CODE]) ON DELETE CASCADE ON UPDATE CASCADE
GO
