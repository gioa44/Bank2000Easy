CREATE TABLE [dbo].[CLI_SET_RIGHTS]
(
[GROUP_ID] [int] NOT NULL,
[SET_ID] [smallint] NOT NULL,
[RIGHT_NAME] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLI_SET_RIGHTS] ADD CONSTRAINT [PK_CLI_SET_RIGHTS] PRIMARY KEY CLUSTERED  ([GROUP_ID], [SET_ID], [RIGHT_NAME]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[CLI_SET_RIGHTS] ADD CONSTRAINT [FK_CLI_SET_RIGHTS_CLI_SET_RIGHT_NAMES] FOREIGN KEY ([RIGHT_NAME]) REFERENCES [dbo].[CLI_SET_RIGHT_NAMES] ([RIGHT_NAME]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CLI_SET_RIGHTS] ADD CONSTRAINT [FK_CLI_SET_RIGHTS_GROUPS] FOREIGN KEY ([GROUP_ID]) REFERENCES [dbo].[GROUPS] ([GROUP_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[CLI_SET_RIGHTS] ADD CONSTRAINT [FK_CLI_SET_RIGHTS_SETS] FOREIGN KEY ([SET_ID]) REFERENCES [dbo].[CLI_SETS] ([SET_ID]) ON DELETE CASCADE ON UPDATE CASCADE
GO
