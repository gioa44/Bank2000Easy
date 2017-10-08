CREATE TABLE [dbo].[INI_DT]
(
[IDS] [char] (20) COLLATE Latin1_General_BIN NOT NULL,
[VALS] [smalldatetime] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[INI_DT] ADD CONSTRAINT [PK_INI_DT] PRIMARY KEY CLUSTERED  ([IDS]) ON [PRIMARY]
GO
