CREATE TABLE [dbo].[CLIENTS_BLOB]
(
[CLIENT_NO] [int] NOT NULL,
[COMMENTS] [text] COLLATE Latin1_General_BIN NULL,
[BLOB_DATA] [image] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENTS_BLOB] ADD CONSTRAINT [PK_CLIENTS_BLOB] PRIMARY KEY CLUSTERED  ([CLIENT_NO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENTS_BLOB] ADD CONSTRAINT [FK_CLIENTS_BLOB_CLIENTS] FOREIGN KEY ([CLIENT_NO]) REFERENCES [dbo].[CLIENTS] ([CLIENT_NO]) ON DELETE CASCADE ON UPDATE CASCADE
GO