CREATE TABLE [dbo].[CLIENT_DOCUMENTS_ARC]
(
[CLI_CHANGE_ID] [int] NOT NULL,
[CLIENT_NO] [int] NOT NULL,
[DOCUMENT_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_DOCUMENTS_ARC] ADD CONSTRAINT [PK_CLIENT_DOCUMENTS_ARC] PRIMARY KEY CLUSTERED  ([CLI_CHANGE_ID], [CLIENT_NO], [DOCUMENT_NAME]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_DOCUMENTS_ARC] ADD CONSTRAINT [FK_CLIENT_DOCUMENTS_ARC_CLI_CHANGES] FOREIGN KEY ([CLI_CHANGE_ID]) REFERENCES [dbo].[CLI_CHANGES] ([REC_ID])
GO
