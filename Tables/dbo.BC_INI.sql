CREATE TABLE [dbo].[BC_INI]
(
[IDS] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[VALS] [varchar] (250) COLLATE Latin1_General_BIN NULL,
[BLOB_VALS] [image] NULL,
[TEXT_VALS] [text] COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[BC_INI_TRIGGER] ON [dbo].[BC_INI] 
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_BC_INI'


GO
ALTER TABLE [dbo].[BC_INI] ADD CONSTRAINT [PK_BC_INI] PRIMARY KEY CLUSTERED  ([IDS]) ON [PRIMARY]
GO
