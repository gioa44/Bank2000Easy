CREATE TABLE [dbo].[BC_TEMPLATES]
(
[REC_ID] [int] NOT NULL IDENTITY(1, 1),
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NOT NULL,
[PAS] [text] COLLATE Latin1_General_BIN NOT NULL,
[DFM] [text] COLLATE Latin1_General_BIN NULL,
[IS_DISABLED] [bit] NOT NULL CONSTRAINT [DF_BC_TEMPLATES_IS_DISABLED] DEFAULT ((0))
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[BC_TEMPLATES_TRIGGER] ON [dbo].[BC_TEMPLATES] 
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_BC_TEMPL'

GO
ALTER TABLE [dbo].[BC_TEMPLATES] ADD CONSTRAINT [PK_BC_TEMPLATES] PRIMARY KEY CLUSTERED  ([REC_ID]) ON [PRIMARY]
GO
