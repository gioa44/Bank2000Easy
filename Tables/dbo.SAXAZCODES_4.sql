CREATE TABLE [dbo].[SAXAZCODES_4]
(
[ID] [smallint] NOT NULL,
[DESCRIP] [varchar] (255) COLLATE Latin1_General_BIN NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[SAXAZCODES_4_TRIGGER] ON [dbo].[SAXAZCODES_4]
FOR INSERT, UPDATE, DELETE 
AS

EXEC dbo._UPDATE_VERSION 'VER_SAXAZCODES_4'
GO
ALTER TABLE [dbo].[SAXAZCODES_4] ADD CONSTRAINT [PK_SAXAZCODES_4] PRIMARY KEY CLUSTERED  ([ID]) ON [PRIMARY]
GO