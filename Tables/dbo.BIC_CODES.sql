CREATE TABLE [dbo].[BIC_CODES]
(
[BIC] [char] (11) COLLATE Latin1_General_BIN NOT NULL,
[DESCRIP] [varchar] (100) COLLATE Latin1_General_BIN NOT NULL,
[CITY] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[COUNTRY] [char] (2) COLLATE Latin1_General_BIN NULL,
[REC_STATE] [tinyint] NOT NULL CONSTRAINT [DF_BIC_CODES_REC_STATE] DEFAULT ((0))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[BIC_CODES_TRIGGER] ON [dbo].[BIC_CODES] 
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_BIC_CODES'
GO
ALTER TABLE [dbo].[BIC_CODES] ADD CONSTRAINT [PK_BIC_CODES] PRIMARY KEY CLUSTERED  ([BIC]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_BIC_CODES] ON [dbo].[BIC_CODES] ([COUNTRY]) ON [PRIMARY]
GO
