CREATE TABLE [dbo].[ACC_SET_RIGHT_NAMES]
(
[RIGHT_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[CATEGORY] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[ACC_SET_RIGHT_NAMES] ADD CONSTRAINT [PK_ACC_SET_RIGHT_NAMES] PRIMARY KEY CLUSTERED  ([RIGHT_NAME]) ON [PRIMARY]
GO
