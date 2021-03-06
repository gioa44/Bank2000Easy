CREATE TABLE [dbo].[KASSYM]
(
[IS_VAL] [tinyint] NOT NULL,
[SYMBOL] [char] (2) COLLATE Latin1_General_BIN NOT NULL,
[SYM_TYPE] [bit] NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[KASSYM_TRIGGER] ON [dbo].[KASSYM] 
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_KASSYM'


GO
ALTER TABLE [dbo].[KASSYM] ADD CONSTRAINT [PK_KASSYM] PRIMARY KEY CLUSTERED  ([IS_VAL], [SYMBOL]) ON [PRIMARY]
GO
