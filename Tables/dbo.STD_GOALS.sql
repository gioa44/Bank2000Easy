CREATE TABLE [dbo].[STD_GOALS]
(
[OWNER] [int] NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[STD_GOALS] ADD CONSTRAINT [PK_STD_GOALS] PRIMARY KEY CLUSTERED  ([OWNER], [DESCRIP]) ON [PRIMARY]
GO
