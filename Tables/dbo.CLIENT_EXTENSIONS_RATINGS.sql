CREATE TABLE [dbo].[CLIENT_EXTENSIONS_RATINGS]
(
[RATING] [varchar] (3) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLIENT_EXTENSIONS_RATINGS] ADD CONSTRAINT [PK_CLIENT_EXTENSIONS_RATINGS] PRIMARY KEY CLUSTERED  ([RATING]) ON [PRIMARY]
GO
