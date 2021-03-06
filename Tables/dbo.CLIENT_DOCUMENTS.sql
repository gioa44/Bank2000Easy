CREATE TABLE [dbo].[CLIENT_DOCUMENTS]
(
[CLIENT_NO] [int] NOT NULL,
[DOCUMENT_NAME] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_DOCUMENTS] ADD CONSTRAINT [PK_CLIENT_DOCUMENTS] PRIMARY KEY CLUSTERED  ([CLIENT_NO], [DOCUMENT_NAME]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_DOCUMENTS] ADD CONSTRAINT [FK_CLIENT_DOCUMENTS_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO
