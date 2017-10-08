CREATE TABLE [dbo].[USER_DOC_TYPES]
(
[DOC_TYPE] [smallint] NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[USER_DOC_TYPES_TRIGGER] ON [dbo].[USER_DOC_TYPES]
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_USER_DOC_TYPES'

GO
ALTER TABLE [dbo].[USER_DOC_TYPES] ADD CONSTRAINT [PK_USER_DOC_TYPES] PRIMARY KEY CLUSTERED  ([DOC_TYPE]) ON [PRIMARY]
GO
