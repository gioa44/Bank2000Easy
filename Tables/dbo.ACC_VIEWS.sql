CREATE TABLE [dbo].[ACC_VIEWS]
(
[ID] [int] NOT NULL IDENTITY(1, 1),
[SCHEMA] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[NAME] [varchar] (128) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (150) COLLATE Latin1_General_BIN NOT NULL,
[SYSTEM] [bit] NOT NULL CONSTRAINT [DF_ACC_VIEWS_SYSTEM] DEFAULT ((0))
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_VIEWS] ADD CONSTRAINT [PK_ACC_VIEWS] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_VIEWS] ADD CONSTRAINT [UK_ACC_VIEWS_DESCRIP] UNIQUE NONCLUSTERED  ([DESCRIP]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_VIEWS] ADD CONSTRAINT [UK_ACC_VIEWS_SCHEMA_NAME] UNIQUE NONCLUSTERED  ([SCHEMA], [NAME]) ON [PRIMARY]
GO
