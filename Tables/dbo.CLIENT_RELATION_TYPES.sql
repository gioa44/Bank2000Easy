CREATE TABLE [dbo].[CLIENT_RELATION_TYPES]
(
[CLIENT_RELATION_TYPE_ID] [smallint] NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[VALUE_TYPE] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_CLIENT_RELATION_TYPES_VALUE_TYPE] DEFAULT ('N'),
[VALUE_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [dbo].[CLIENT_RELATION_TYPES_TRIGGER] ON [dbo].[CLIENT_RELATION_TYPES] 
FOR INSERT, UPDATE, DELETE 
AS

EXEC _UPDATE_VERSION 'VER_CLIENT_REL_TYPES'
GO
ALTER TABLE [dbo].[CLIENT_RELATION_TYPES] ADD CONSTRAINT [PK_CLIENT_RELATION_TYPES] PRIMARY KEY CLUSTERED  ([CLIENT_RELATION_TYPE_ID]) ON [PRIMARY]
GO
