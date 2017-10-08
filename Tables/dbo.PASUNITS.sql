CREATE TABLE [dbo].[PASUNITS]
(
[UNITNAME] [varchar] (20) COLLATE Latin1_General_BIN NOT NULL,
[PAS] [text] COLLATE Latin1_General_BIN NOT NULL,
[DFM] [text] COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[PASUINITS_TRIGGER] ON [dbo].[PASUNITS]
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_PASUNITS'


GO
ALTER TABLE [dbo].[PASUNITS] ADD CONSTRAINT [PK_PASUNITS] PRIMARY KEY CLUSTERED  ([UNITNAME]) ON [PRIMARY]
GO