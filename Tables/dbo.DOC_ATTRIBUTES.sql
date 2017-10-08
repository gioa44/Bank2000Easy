CREATE TABLE [dbo].[DOC_ATTRIBUTES]
(
[REC_ID] [int] NOT NULL,
[ATTRIB_CODE] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[ATTRIB_VALUE] [varchar] (1000) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_ATTRIBUTES] ADD CONSTRAINT [PK_DOC_ATTRIBUTES] PRIMARY KEY CLUSTERED  ([REC_ID], [ATTRIB_CODE]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[DOC_ATTRIBUTES] ADD CONSTRAINT [FK_DOC_ATTRIBUTES_DOC_ATTRIB_CODES] FOREIGN KEY ([ATTRIB_CODE]) REFERENCES [dbo].[DOC_ATTRIB_CODES] ([CODE]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[DOC_ATTRIBUTES] ADD CONSTRAINT [FK_DOC_ATTRIBUTES_OPS] FOREIGN KEY ([REC_ID]) REFERENCES [dbo].[OPS_0000] ([REC_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
