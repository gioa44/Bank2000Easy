CREATE TABLE [dbo].[INI_STR]
(
[IDS] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[VALS] [varchar] (255) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[INI_STR] ADD CONSTRAINT [PK_INI_STR] PRIMARY KEY CLUSTERED  ([IDS]) ON [PRIMARY]
GO
