CREATE TABLE [dbo].[INI_MONEY]
(
[IDS] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[VALS] [money] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[INI_MONEY] ADD CONSTRAINT [PK_INI_MONEY] PRIMARY KEY CLUSTERED  ([IDS]) ON [PRIMARY]
GO
