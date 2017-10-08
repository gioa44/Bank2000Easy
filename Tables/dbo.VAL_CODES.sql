CREATE TABLE [dbo].[VAL_CODES]
(
[ISO] [dbo].[TISO] NOT NULL,
[DESCRIP] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[DIGITS] [tinyint] NOT NULL CONSTRAINT [DF_VAL_CODES_DIGITS] DEFAULT ((2)),
[ISO_TYPE] [tinyint] NOT NULL CONSTRAINT [DF_VAL_CODES_ISO_TYPE] DEFAULT ((4)),
[COUNTRY] [char] (2) COLLATE Latin1_General_BIN NULL,
[IS_DISABLED] [bit] NOT NULL CONSTRAINT [DF_VAL_CODES_IS_DISABLED] DEFAULT ((0)),
[DESCRIP_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UNIT_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[UNIT_NAME_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CENT_NAME] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[CENT_NAME_LAT] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[ISO_NUM] [smallint] NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE TRIGGER [dbo].[VAL_CODES_TRIGGER] ON [dbo].[VAL_CODES] 
FOR INSERT, UPDATE, DELETE 
AS
EXEC _UPDATE_VERSION 'VER_VAL_CODES'


GO
ALTER TABLE [dbo].[VAL_CODES] WITH NOCHECK ADD CONSTRAINT [CK_VAL_CODES_1] CHECK (([DIGITS]>=(0) AND [DIGITS]<=(4)))
GO
ALTER TABLE [dbo].[VAL_CODES] WITH NOCHECK ADD CONSTRAINT [CK_VAL_CODES_2] CHECK (([ISO_TYPE]=(4) OR [ISO_TYPE]=(2)))
GO
ALTER TABLE [dbo].[VAL_CODES] ADD CONSTRAINT [PK_VAL_CODES] PRIMARY KEY CLUSTERED  ([ISO]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[VAL_CODES] WITH NOCHECK ADD CONSTRAINT [FK_VAL_CODES_COUNTRIES] FOREIGN KEY ([COUNTRY]) REFERENCES [dbo].[COUNTRIES] ([COUNTRY])
GO